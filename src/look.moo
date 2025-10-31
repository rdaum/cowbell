object LOOK
  name: "Object 'look' Flyweight Delegate"
  parent: ROOT
  owner: HACKER

  override description = "The $look flyweight delegate holds the attributes involved in looking at an object, and can be transformed into output events. It always has mandatory 'title and 'description slots, and then optional contents which are a series of integration descriptions.";
  override import_export_id = "look";

  verb mk (this none this) owner: HACKER flags: "rxd"
    {what, @contents} = args;
    return <this, [what -> what, title -> what:name(), description -> what:description()], {@contents}>;
  endverb

  verb into_event (this none this) owner: HACKER flags: "rxd"
    "Three lines -- title, description, contents.";
    "Description is the item description but is also appended to with integrations. Objects with an :integrate_description verb are put there.";
    "The remainder go into the contents block.";
    "Title is the direct-object-capitalized";
    title = $title:mk($sub:dc());
    integrated_contents = {};
    contents = {};
    for o in (this)
      if (o == player)
        continue;
      endif
      integrated_description = `o:integrate_description() ! E_VERBNF => false';
      if (integrated_description)
        integrated_contents = {@integrated_contents, integrated_description};
      else
        contents = {@contents, `o:name() ! E_VERBNF => o.name'};
      endif
    endfor
    description = this.description;
    if (length(integrated_contents))
      description = description + " " + { ic + "." for ic in (integrated_contents) }:to_list();
    endif
    block_elements = {title, description};
    if (length(contents))
      block_elements = {@block_elements, "You see " + contents:english_list() + " here."};
    endif
    b = $block:mk(@block_elements);
    return $event:mk_look(player, b):with_dobj(this.what);
  endverb

  verb validate (this none this) owner: HACKER flags: "rxd"
    if (typeof(this) != FLYWEIGHT)
      return false;
    endif
    try
      this.what && this.title && this.description && return true;
    except (E_PROPNF)
      return false;
    endtry
    return true;
  endverb
endobject