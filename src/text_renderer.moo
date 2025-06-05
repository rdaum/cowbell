object TEXT_RENDERER
  name: "Text/Plain Content Renderer"
  parent: BASE_RENDERER
  location: FIRST_ROOM
  owner: HACKER
  readable: true

  override description = "Renders events as plain text content, compatible with the existing event system while providing improved structure.";

  verb get_supported_types (this none this) owner: HACKER flags: "rxd"
    "Returns list of content types this renderer supports.";
    return {"text/plain", "text/moo"};
  endverb

  verb get_priority (this none this) owner: HACKER flags: "rxd"
    "Text renderer has medium priority.";
    return 10;
  endverb

  verb render (this none this) owner: HACKER flags: "rxd"
    "Renders an event as plain text using the existing transform logic.";
    {event, context, ?options = []} = args;
    if (!this:validate_context(context))
      raise(E_INVARG, "Invalid rendering context");
    endif
    if (!event:validate())
      raise(E_INVARG, "Invalid event structure");
    endif
    target_user = context['target_user];
    content_type = context['content_type];
    if (!this:can_render(content_type))
      raise(E_INVARG, "Unsupported content type: " + content_type);
    endif
    raw_content = event:transform_for(target_user, content_type);
    processed_content = this:post_process_text(raw_content, context, options);
    return ['content -> processed_content, 'content_type -> content_type, 'success -> true];
  endverb

  verb post_process_text (this none this) owner: HACKER flags: "rxd"
    "Post-process text content with optional formatting and cleanup.";
    {raw_content, context, options} = args;
    if (typeof(raw_content) != LIST)
      return raw_content;
    endif
    result = raw_content;
    if (`options['trim_empty_lines] ! E_PROPNF, E_RANGE => false')
      result = this:trim_empty_lines(result);
    endif
    max_lines = `options['max_lines] ! E_PROPNF, E_RANGE => 0';
    if (typeof(max_lines) == INT && max_lines > 0 && length(result) > max_lines)
      result = result[1..max_lines];
      result = {@result, "... (truncated)"};
    endif
    return result;
  endverb

  verb trim_empty_lines (this none this) owner: HACKER flags: "rxd"
    "Remove empty lines from the beginning and end of content.";
    {lines} = args;
    if (typeof(lines) != LIST || !length(lines))
      return lines;
    endif
    start_idx = 1;
    end_idx = length(lines);
    while (start_idx <= end_idx && (!(lines[start_idx]) || lines[start_idx] == ""))
      start_idx = start_idx + 1;
    endwhile
    while (end_idx >= start_idx && (!(lines[end_idx]) || lines[end_idx] == ""))
      end_idx = end_idx - 1;
    endwhile
    return start_idx > end_idx ? {} | lines[start_idx..end_idx];
  endverb

  verb test_text_renderer_basic (this none this) owner: HACKER flags: "rxd"
    "Test basic text renderer functionality.";
    supported = this:get_supported_types();
    length(supported) < 1 && raise(e_assert, "Should support at least one content type");
    this:can_render("text/plain") || raise(e_assert, "Should support text/plain");
    !this:can_render("application/json") || raise(e_assert, "Should not support JSON");
    typeof(this:get_priority()) == INT || raise(e_assert, "Priority should be integer");
  endverb

  verb test_text_renderer_post_processing (this none this) owner: HACKER flags: "rxd"
    "Test text post-processing features.";
    lines = {"", "hello", "world", ""};
    trimmed = this:trim_empty_lines(lines);
    length(trimmed) != 2 && raise(e_assert, "Should trim to 2 lines, got " + toliteral(trimmed));
    trimmed[1] != "hello" && raise(e_assert, "First line should be 'hello'");
    trimmed[2] != "world" && raise(e_assert, "Second line should be 'world'");
    context = ['content_type -> "text/plain", 'target_user -> #4];
    options = ['trim_empty_lines -> true, 'max_lines -> 1];
    processed = this:post_process_text({"", "line1", "line2", ""}, context, options);
    length(processed) <= 2 && processed[1] == "line1" || raise(e_assert, "Post-processing failed: " + toliteral(processed));
  endverb

  verb test_text_renderer_with_event (this none this) owner: HACKER flags: "rxd"
    "Test rendering with actual event (requires EVENT object).";
    if (!$event)
      return;
    endif
    test_event = $event:mk_test(player, "Hello world");
    context = ['content_type -> "text/plain", 'target_user -> player];
    try
      result = this:render(test_event, context);
      typeof(result) == MAP || raise(e_assert, "Result should be a map");
      'content in result || raise(e_assert, "Result should have content");
      result['success] || raise(e_assert, "Rendering should succeed");
    except e (ANY)
      if (e != E_VERBNF)
        raise(e);
      endif
    endtry
  endverb
endobject
