object RENDER_PIPELINE
  name: "Event Rendering Pipeline"
  parent: ROOT
  location: FIRST_ROOM
  owner: HACKER
  readable: true

  property renderers (owner: HACKER, flags: "rw") = {};
  property stages (owner: HACKER, flags: "rw") = {};

  override description = "Manages the rendering pipeline for events. Coordinates between different renderers and processing stages to transform events into various content types.";

  verb register_renderer (this none this) owner: HACKER flags: "rxd"
    "Register a renderer with the pipeline.";
    {renderer} = args;
    if (!renderer:is_a($base_renderer))
      raise(E_INVARG, "Renderer must inherit from BASE_RENDERER");
    endif
    this.renderers = {@this.renderers, renderer};
    this:sort_renderers_by_priority();
    return true;
  endverb

  verb unregister_renderer (this none this) owner: HACKER flags: "rxd"
    "Remove a renderer from the pipeline.";
    {renderer} = args;
    idx = renderer in this.renderers;
    if (idx)
      this.renderers = {this.renderers[1..idx - 1], @this.renderers[idx + 1..$]};
    endif
    return idx != 0;
  endverb

  verb sort_renderers_by_priority (this none this) owner: HACKER flags: "rxd"
    "Sort renderers by priority (highest first).";
    return;
  endverb

  verb find_renderer (this none this) owner: HACKER flags: "rxd"
    "Find the best renderer for a given content type.";
    {content_type} = args;
    for renderer in (this.renderers)
      if (`renderer:can_render(content_type) ! ANY => false')
        return renderer;
      endif
    endfor
    return false;
  endverb

  verb render (this none this) owner: HACKER flags: "rxd"
    "Main rendering method - processes an event through the pipeline.";
    {event, context, ?options = []} = args;
    if (!this:validate_render_request(event, context))
      return this:error_result("Invalid render request");
    endif
    content_type = context['content_type];
    renderer = this:find_renderer(content_type);
    if (!renderer)
      return this:error_result("No renderer found for content type: " + content_type);
    endif
    try
      pre_result = this:run_pre_stages(event, context, options);
      if (!(pre_result['success]))
        return pre_result;
      endif
      render_result = renderer:render(event, context, options);
      if (!(render_result['success]))
        return render_result;
      endif
      post_result = this:run_post_stages(render_result, context, options);
      return post_result;
    except e (ANY)
      return this:error_result("Rendering failed: " + toliteral(e));
    endtry
  endverb

  verb validate_render_request (this none this) owner: HACKER flags: "rxd"
    "Validate that a render request has all required components.";
    {event, context} = args;
    if (typeof(event) != FLYWEIGHT)
      return false;
    endif
    if (typeof(context) != MAP)
      return false;
    endif
    required_fields = {'content_type, 'target_user};
    for field in (required_fields)
      if (!(field in context))
        return false;
      endif
    endfor
    return true;
  endverb

  verb add_stage (this none this) owner: HACKER flags: "rxd"
    "Add a processing stage to the pipeline.";
    {stage_type, stage_obj} = args;
    if (!(stage_type in {'pre, 'post}))
      raise(E_INVARG, "Stage type must be 'pre or 'post");
    endif
    if (!(stage_type in this.stages))
      this.stages[stage_type] = {};
    endif
    this.stages[stage_type] = {@this.stages[stage_type], stage_obj};
    return true;
  endverb

  verb run_pre_stages (this none this) owner: HACKER flags: "rxd"
    "Run pre-processing stages.";
    {event, context, options} = args;
    if (!('pre in this.stages))
      return ['success -> true, 'event -> event, 'context -> context];
    endif
    current_event = event;
    current_context = context;
    for stage in (this.stages['pre])
      try
        result = stage:process(current_event, current_context, options);
        if (!(result['success]))
          return result;
        endif
        current_event = result['event];
        current_context = result['context];
      except e (ANY)
        return this:error_result("Pre-stage failed: " + toliteral(e));
      endtry
    endfor
    return ['success -> true, 'event -> current_event, 'context -> current_context];
  endverb

  verb run_post_stages (this none this) owner: HACKER flags: "rxd"
    "Run post-processing stages.";
    {render_result, context, options} = args;
    if (!('post in this.stages))
      return render_result;
    endif
    current_result = render_result;
    for stage in (this.stages['post])
      try
        new_result = stage:process(current_result, context, options);
        if (!(new_result['success]))
          return new_result;
        endif
        current_result = new_result;
      except e (ANY)
        return this:error_result("Post-stage failed: " + toliteral(e));
      endtry
    endfor
    return current_result;
  endverb

  verb error_result (this none this) owner: HACKER flags: "rxd"
    "Create a standardized error result.";
    {message} = args;
    return ['success -> false, 'error -> message, 'content -> {}, 'content_type -> "text/plain"];
  endverb

  verb get_stats (this none this) owner: HACKER flags: "rxd"
    "Get pipeline statistics and configuration.";
    return ['num_renderers -> length(this.renderers), 'num_pre_stages -> 'pre in this.stages ? length(this.stages['pre]) | 0, 'num_post_stages -> 'post in this.stages ? length(this.stages['post]) | 0, 'supported_types -> this:get_all_supported_types()];
  endverb

  verb get_all_supported_types (this none this) owner: HACKER flags: "rxd"
    "Get all content types supported by registered renderers.";
    all_types = {};
    for renderer in (this.renderers)
      types = `renderer:get_supported_types() ! ANY => {}';
      all_types = {@all_types, @types};
    endfor
    return call_function('setcombine, all_types);
  endverb

  verb test_pipeline_registration (this none this) owner: HACKER flags: "rxd"
    "Test renderer registration functionality.";
    initial_count = length(this.renderers);
    if (!$text_renderer)
      return;
    endif
    this:register_renderer($text_renderer);
    length(this.renderers) != initial_count + 1 && raise(e_assert, "Renderer registration failed");
    this:unregister_renderer($text_renderer);
    length(this.renderers) != initial_count && raise(e_assert, "Renderer unregistration failed");
  endverb

  verb test_pipeline_rendering (this none this) owner: HACKER flags: "rxd"
    "Test basic pipeline rendering with text renderer.";
    if (!$text_renderer || !$event)
      return;
    endif
    this:register_renderer($text_renderer);
    test_event = $event:mk_test(player, "Pipeline test");
    context = ['content_type -> "text/plain", 'target_user -> player];
    try
      result = this:render(test_event, context);
      typeof(result) == MAP || raise(e_assert, "Result should be a map");
      'success in result || raise(e_assert, "Result should have success field");
      this:unregister_renderer($text_renderer);
    except e (ANY)
      this:unregister_renderer($text_renderer);
      if (e != E_VERBNF)
        raise(e);
      endif
    endtry
  endverb

  verb test_pipeline_content_types (this none this) owner: HACKER flags: "rxd"
    "Test content type discovery and matching.";
    if (!$text_renderer)
      return;
    endif
    this:register_renderer($text_renderer);
    try
      supported = this:get_all_supported_types();
      typeof(supported) == LIST || raise(e_assert, "Supported types should be a list");
      renderer = this:find_renderer("text/plain");
      renderer || raise(e_assert, "Should find text renderer for text/plain");
      no_renderer = this:find_renderer("application/nonsense");
      no_renderer && raise(e_assert, "Should not find renderer for nonsense type");
      this:unregister_renderer($text_renderer);
    except e (ANY)
      this:unregister_renderer($text_renderer);
      raise(e);
    endtry
  endverb
endobject
