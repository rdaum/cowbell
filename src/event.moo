object EVENT
  name: "Event Flyweight Delegate"
  parent: ROOT
  location: FIRST_ROOM
  owner: HACKER
  readable: true

  override description = "Flyweight delegate for events that happen in the world and which become output to send to the player. Slots must include 'action, 'actor, 'timestamp, 'dobj, 'iobj, 'this_obj. Content to display to the player is produced by iterating the contents and calling :transform_for(this, content_type) on them, appending them together, which in the end returns a string which is meant to be sent as content_type.";

  verb "mk_*" (this none this) owner: HACKER flags: "rxd"
    "mk_<verb>(actor, ... content ... )";
    action = verb[4..length(verb)];
    {actor, @content} = args;
    return <this, [actor -> actor, verb -> action, dobj -> false, iobj -> false, timestamp -> time(), this_obj -> false], {@content}>;
  endverb

  verb "with_dobj with_iobj with_this" (this none this) owner: HACKER flags: "rxd"
    {value} = args;
    wut = tosym(verb[6..length(verb)]);
    wut = wut == 'this ? 'this_obj | wut;
    return add_slot(this, wut, value);
  endverb

  verb transform_for (this none this) owner: HACKER flags: "rxd"
    "Call 'render_as(content_type, this)' on all content, and append into a final string.";
    {render_for, ?content_type = "text/plain"} = args;
    if (!this:validate())
      raise(E_INVARG);
    endif
    results = {};
    for entry in (this)
      if (typeof(entry) == FLYWEIGHT)
        entry = entry:render_as(render_for, content_type, this);
      endif
      if (typeof(entry) == STR)
        results = entry:append_to_paragraph(@results);
      elseif (typeof(entry) == LIST)
        for index in [1..length(entry)]
          results = {@(entry[index]):append_to_paragraph(@results)};
          if (index != length(entry))
            results = {@results, ""};
          endif
        endfor
      else
        raise(E_TYPE, "Invalid type in event content", entry);
      endif
    endfor
    return results;
  endverb

  verb render_with_pipeline (this none this) owner: HACKER flags: "rxd"
    "New pipeline-based rendering method with enhanced capabilities.";
    {render_for, ?content_type = "text/plain", ?options = []} = args;
    if (!$render_pipeline)
      return this:transform_for(render_for, content_type);
    endif
    context = ['content_type -> content_type, 'target_user -> render_for, 'event_type -> this.verb, 'timestamp -> this.timestamp];
    try
      result = $render_pipeline:render(this, context, options);
      if (result['success])
        return result['content];
      else
        return this:transform_for(render_for, content_type);
      endif
    except e (ANY)
      return this:transform_for(render_for, content_type);
    endtry
  endverb

  verb render (this none this) owner: HACKER flags: "rxd"
    "Primary rendering method - uses pipeline if available, falls back to legacy.";
    {render_for, ?content_type = "text/plain", ?options = []} = args;
    return this:render_with_pipeline(render_for, content_type, options);
  endverb

  verb validate (this none this) owner: HACKER flags: "rxd"
    "Validate that the event has all the correct fields. Return false if not.";
    if (typeof(this) != FLYWEIGHT)
      return false;
    endif
    try
      this.verb && this.actor && this.timestamp && this.this_obj && this.dobj && this.iobj;
      return true;
    except (E_PROPNF)
      return false;
    endtry
  endverb

  verb test_event_pipeline_integration (this none this) owner: HACKER flags: "rxd"
    "Test integration with the new rendering pipeline.";
    test_event = this:mk_test(player, "Pipeline integration test");
    !test_event:validate() && raise(e_assert, "Test event should be valid");
    legacy_result = test_event:transform_for(player, "text/plain");
    typeof(legacy_result) == LIST || raise(e_assert, "Legacy rendering should return list");
    if ($render_pipeline && $text_renderer)
      $render_pipeline:register_renderer($text_renderer);
    try
        pipeline_result = test_event:render(player, "text/plain");
        typeof(pipeline_result) == LIST || raise(e_assert, "Pipeline rendering should return list");
    finally
        $render_pipeline:unregister_renderer($text_renderer);
      endtry
    endif
  endverb

  verb test_event_creation_and_modification (this none this) owner: HACKER flags: "rxd"
    "Test event creation and object modification methods.";
    base_event = this:mk_action(player, "Hello world");
    !base_event:validate() && raise(e_assert, "Base event should be valid");
    base_event.verb != "action" && raise(e_assert, "Event verb should be 'action'");
    with_dobj = base_event:with_dobj($first_room);
    with_dobj.dobj != $first_room && raise(e_assert, "Should set dobj correctly");
    with_iobj = with_dobj:with_iobj(player);
    with_iobj.iobj != player && raise(e_assert, "Should set iobj correctly");
    with_this = with_iobj:with_this($first_room);
    with_this.this_obj != $first_room && raise(e_assert, "Should set this_obj correctly");
    !with_this:validate() && raise(e_assert, "Modified event should still be valid");
  endverb

  verb test_event_content_types (this none this) owner: HACKER flags: "rxd"
    "Test rendering with different content types.";
    test_event = this:mk_test(player, "Content type test");
    text_result = test_event:render(player, "text/plain");
    typeof(text_result) == LIST || raise(e_assert, "Text rendering should return list");
    if ($render_pipeline && $html_renderer)
      $render_pipeline:register_renderer($html_renderer);
    try
        html_result = test_event:render(player, "text/html");
        typeof(html_result) == LIST || raise(e_assert, "HTML rendering should return list");
    finally
        $render_pipeline:unregister_renderer($html_renderer);
      endtry
    endif
  endverb
endobject
