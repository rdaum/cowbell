object BASE_RENDERER
  name: "Base Renderer Interface"
  parent: ROOT
  location: FIRST_ROOM
  owner: HACKER
  readable: true

  override description = "Base interface for all content renderers. Provides common functionality and defines the contract that all renderers must implement.";

  verb can_render (this none this) owner: HACKER flags: "rxd"
    "Returns true if this renderer can handle the given content type.";
    {content_type} = args;
    return content_type in this:get_supported_types();
  endverb

  verb get_supported_types (this none this) owner: HACKER flags: "rxd"
    "Returns a list of content types this renderer supports. Override in subclasses.";
    return {};
  endverb

  verb render (this none this) owner: HACKER flags: "rxd"
    "Main rendering method. Override in subclasses.";
    {event, context, ?options = []} = args;
    raise(E_VERBNF, "render method must be implemented by subclasses");
  endverb

  verb validate_context (this none this) owner: HACKER flags: "rxd"
    "Validates that the rendering context has required fields.";
    {context} = args;
    if (typeof(context) != MAP)
      return false;
    endif
    has_content_type = `context['content_type] ! E_PROPNF, E_RANGE => $nothing';
    has_target_user = `context['target_user] ! E_PROPNF, E_RANGE => $nothing';
    return has_content_type != $nothing && has_target_user != $nothing;
  endverb

  verb get_priority (this none this) owner: HACKER flags: "rxd"
    "Returns rendering priority (higher numbers = higher priority). Override in subclasses.";
    return 0;
  endverb

  verb test_base_renderer_interface (this none this) owner: HACKER flags: "rxd"
    "Test basic renderer interface functionality.";
    context = ['content_type -> "text/plain", 'target_user -> #4];
    !this:validate_context(context) && raise(e_assert, "Context validation failed");
    this:can_render("nonexistent/type") && raise(e_assert, "Should not support nonexistent type");
    typeof(this:get_supported_types()) != LIST && raise(e_assert, "get_supported_types must return list");
    typeof(this:get_priority()) != INT && raise(e_assert, "get_priority must return integer");
  endverb
endobject
