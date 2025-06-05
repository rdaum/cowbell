object HTML_TIME
  name: "HTML Time Tag Delegate"
  parent: ROOT
  location: FIRST_ROOM
  owner: HACKER
  readable: true

  property tag (owner: HACKER, flags: "r") = "time";

  override description = "Delegate object for HTML time elements.";
endobject
