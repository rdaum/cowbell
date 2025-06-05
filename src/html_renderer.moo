object HTML_RENDERER
  name: "HTML Content Renderer"
  parent: BASE_RENDERER
  location: FIRST_ROOM
  owner: HACKER
  readable: true

  override description = "Renders events as structured HTML using flyweights and the to_xml builtin. This creates semantic markup that can be styled with CSS and manipulated with JavaScript.";

  verb get_supported_types (this none this) owner: HACKER flags: "rxd"
    "Returns list of content types this renderer supports.";
    return {"text/html", "application/xhtml+xml", "application/xml"};
  endverb

  verb get_priority (this none this) owner: HACKER flags: "rxd"
    "XML HTML renderer has highest priority for rich web clients.";
    return 30;
  endverb

  verb render (this none this) owner: HACKER flags: "rxd"
    "Renders an event as structured HTML using flyweights.";
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
    try
      html_flyweight = this:event_to_flyweight(event, context, options);
      xml_string = to_xml(html_flyweight);
      return ['content -> {xml_string}, 'content_type -> content_type, 'success -> true];
    except e (ANY)
      return ['content -> {}, 'error -> "Failed to convert event to XML: " + toliteral(e), 'content_type -> content_type, 'success -> false];
    endtry
  endverb

  verb event_to_flyweight (this none this) owner: HACKER flags: "rxd"
    "Convert an event into a structured HTML flyweight.";
    {event, context, options} = args;
    css_classes = `options['css_classes] ! E_PROPNF, E_RANGE => {}';
    include_timestamp = `options['include_timestamp] ! E_PROPNF, E_RANGE => false';
    event_type = event.verb;
    base_classes = {"moo-event", "event-" + event_type};
    all_classes = {@base_classes, @css_classes};
    class_str = all_classes:english_list(" ");
    contents = this:build_event_content(event, context, options);
    if (include_timestamp)
      contents = {"[TIMESTAMP]", @contents};
    endif
    return <$html_div, [class -> class_str], {@contents}>;
  endverb

  verb build_event_content (this none this) owner: HACKER flags: "rxd"
    "Build the content elements for different event types.";
    {event, context, options} = args;
    if (event.verb == "look")
      return this:build_look_content(event, context, options);
    elseif (event.verb == "say")
      return this:build_say_content(event, context, options);
    else
      return this:build_generic_content(event, context, options);
    endif
  endverb

  verb build_look_content (this none this) owner: HACKER flags: "rxd"
    "Build structured content for look events.";
    {event, context, options} = args;
    raw_content = event:transform_for(context['target_user], "text/plain");
    contents = {};
    for line in (raw_content)
      if (line && line != "")
        para = <$html_p, [class -> "look-line"], {this:escape_html(line)}>;
        contents = {@contents, para};
      endif
    endfor
    return contents;
  endverb

  verb build_say_content (this none this) owner: HACKER flags: "rxd"
    "Build structured content for say events.";
    {event, context, options} = args;
    speaker_name = `event.actor:name() ! E_VERBNF => "Someone"';
    speaker_span = <$html_span, [class -> "speaker"], {speaker_name}>;
    raw_content = event:transform_for(context['target_user], "text/plain");
    message_text = raw_content:english_list(" ");
    message_span = <$html_span, [class -> "message"], {this:escape_html(message_text)}>;
    return {speaker_span, ": ", message_span};
  endverb

  verb build_generic_content (this none this) owner: HACKER flags: "rxd"
    "Build content for generic events.";
    {event, context, options} = args;
    raw_content = event:transform_for(context['target_user], "text/plain");
    contents = {};
    for line in (raw_content)
      if (line && line != "")
        contents = {@contents, this:escape_html(line)};
      endif
    endfor
    return contents;
  endverb

  verb escape_html (this none this) owner: HACKER flags: "rxd"
    "Escape HTML special characters in text content.";
    {text} = args;
    if (typeof(text) != STR)
      text = tostr(text);
    endif
    text = strsub(text, "&", "&amp;");
    text = strsub(text, "<", "&lt;");
    text = strsub(text, ">", "&gt;");
    text = strsub(text, "\"", "&quot;");
    text = strsub(text, "'", "&#39;");
    return text;
  endverb

  verb test_html_renderer_basic (this none this) owner: HACKER flags: "rxd"
    "Test basic HTML renderer functionality.";
    supported = this:get_supported_types();
    length(supported) >= 1 || raise(e_assert, "Should support at least one content type");
    this:can_render("text/html") || raise(e_assert, "Should support text/html");
    this:can_render("application/xml") || raise(e_assert, "Should support application/xml");
    typeof(this:get_priority()) == INT || raise(e_assert, "Priority should be integer");
  endverb
endobject
