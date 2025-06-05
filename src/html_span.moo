object HTML_SPAN
  name: "HTML Span Tag Delegate"
  parent: ROOT
  location: FIRST_ROOM
  owner: HACKER
  readable: true

  property tag (owner: HACKER, flags: "r") = "span";

  override description = "Delegate object for HTML span elements.";
endobject
