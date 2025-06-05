object PLAYER
  name: "Generic Player"
  parent: ROOT
  location: FIRST_ROOM
  owner: WIZ
  fertile: true
  readable: true

  property password (owner: ARCH_WIZARD, flags: "");
  property po (owner: HACKER, flags: "rc") = "it";
  property pp (owner: HACKER, flags: "rc") = "its";
  property pq (owner: HACKER, flags: "rc") = "its";
  property pr (owner: HACKER, flags: "rc") = "itself";
  property preferred_content_type (owner: HACKER, flags: "rw") = "text/plain";
  property ps (owner: HACKER, flags: "rc") = "it";

  override description = "You see a player who should get around to describing themself.";

  verb "l look" (any none none) owner: ARCH_WIZARD flags: "rxd"
    "Look at an object. Collects the descriptive attributes and then emits them to the player.";
    "If we don't have a match, that's a 'I don't see that there...'";
    if (dobjstr == "")
      global dobj = player.location;
    endif
    !valid(dobj) && return this:tell(this:msg_no_dobj_match());
    look_d = dobj:look_self();
    player:tell(look_d:into_event());
  endverb

  verb "msg_no_dobj_match msg_no_iobj_match" (this none this) owner: HACKER flags: "rxd"
    return $event:mk_not_found(player, "I don't see that here.");
  endverb

  verb "pronoun_*" (this none this) owner: HACKER flags: "rxd"
    ptype = tosym(verb[9..length(verb)]);
    ptype == 'subject && return this.ps;
    ptype == 'object && return this.po;
    ptype == 'posessive && args[1] == 'adj && return this.pp;
    ptype == 'posessive && args[2] == 'noun && return this.pq;
    ptype == 'reflexive && return this.pr;
    raise(E_INVARG);
  endverb

  verb tell (this none this) owner: ARCH_WIZARD flags: "rxd"
    set_task_perms(this);
    {events, ?content_type = 0} = args;
    if (content_type == 0)
      content_type = this:get_preferred_content_type();
    endif
    if (typeof(events) != LIST)
      events = {events};
    endif
    for event in (events)
      if (typeof(event) == STR)
        content = event;
      else
        content = this:render_event(event, content_type);
      endif
      if (typeof(content) == LIST)
        { notify(this, line, tosym(content_type)) for line in (content) };
      else
        notify(this, content, tosym(content_type));
      endif
    endfor
  endverb

  verb acceptable (this none this) owner: HACKER flags: "rxd"
    return !is_player(args[1]);
  endverb

  verb get_preferred_content_type (this none this) owner: HACKER flags: "rxd"
    "Returns the preferred content type for this player (e.g. 'text/plain', 'text/html').";
    return `this.preferred_content_type ! E_PROPNF, E_RANGE => "text/plain"';
  endverb

  verb render_event (this none this) owner: HACKER flags: "rxd"
    "Renders an event using the rendering pipeline for the specified content type.";
    {event, content_type} = args;
    context = ['target_user -> this, 'content_type -> content_type];
    result = `$render_pipeline:render(event, context) ! ANY => 0';
    if (result == 0 || !(result['success]))
      return event:transform_for(this, content_type);
    endif
    return result['content];
  endverb

  verb mk_emote_event (this none this) owner: HACKER flags: "rxd"
    return $event:mk_emote(this, $sub:nc(), " ", args[1]):with_this(this.location);
  endverb

  verb mk_say_event (this none this) owner: HACKER flags: "rxd"
    return $event:mk_say(this, $sub:nc(), " ", $sub:self_alt("say", "says"), ", \"", args[1], "\""):with_this(this.location);
  endverb

  verb mk_connected_event (this none this) owner: HACKER flags: "rxd"
    return $event:mk_say(this, $sub:nc(), " ", $sub:self_alt("have", "has"), " connected.");
  endverb

  verb mk_connected_event (this none this) owner: HACKER flags: "rxd"
    return $event:mk_say(this, $sub:nc(), " ", $sub:self_alt("have", "has"), " disconnected.");
  endverb

  verb test_player_rendering (this none this) owner: HACKER flags: "rxd"
    "Test that player rendering pipeline integration works.";
    this:get_preferred_content_type() || raise(e_assert, "Should have preferred content type");
    typeof(this:get_preferred_content_type()) == STR || raise(e_assert, "Content type should be string");
    test_event = $event:mk_say(this, "Hello World"):with_this($first_room);
    typeof(this:render_event(test_event, "text/plain")) == LIST || raise(e_assert, "Should render to list of strings");
    this.preferred_content_type = "text/html";
    this:get_preferred_content_type() == "text/html" || raise(e_assert, "Should use set content type");
  endverb
endobject
