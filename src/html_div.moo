object HTML_DIV
  name: "HTML Div Tag Delegate"
  parent: ROOT
  location: FIRST_ROOM
  owner: HACKER
  readable: true

  property tag (owner: HACKER, flags: "r") = "div";

  override description = "Delegate object for HTML div elements in flyweight-based rendering.";
endobject
