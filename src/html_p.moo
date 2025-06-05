object HTML_P
  name: "HTML Paragraph Tag Delegate"
  parent: ROOT
  location: FIRST_ROOM
  owner: HACKER
  readable: true

  property tag (owner: HACKER, flags: "r") = "p";

  override description = "Delegate object for HTML paragraph elements.";
endobject
