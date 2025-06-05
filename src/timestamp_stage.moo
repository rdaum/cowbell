object TIMESTAMP_STAGE
  name: "Timestamp Processing Stage"
  parent: ROOT
  location: FIRST_ROOM
  owner: HACKER
  readable: true

  override description = "Example processing stage that adds timestamp formatting to rendered content. Demonstrates how to extend the rendering pipeline with custom processing stages.";

  verb process (this none this) owner: HACKER flags: "rxd"
    "Process rendered content to add timestamp information.";
    {input, context, options} = args;
    add_timestamps = `options['add_timestamps] ! E_PROPNF, E_RANGE => false';
    if (!add_timestamps)
      return input;
    endif
    content = `input['content] ! E_PROPNF, E_RANGE => {}';
    if (typeof(content) == LIST)
      timestamp_str = this:format_timestamp(time(), options);
      new_content = {timestamp_str, @content};
      result = input;
      result['content] = new_content;
      return result;
    endif
    return input;
  endverb

  verb format_timestamp (this none this) owner: HACKER flags: "rxd"
    "Format a timestamp for display.";
    {timestamp, options} = args;
    format = `options['timestamp_format] ! E_PROPNF, E_RANGE => "simple"';
    if (format == "iso")
      return this:format_iso_timestamp(timestamp);
    elseif (format == "friendly")
      return this:format_friendly_timestamp(timestamp);
    else
      return "[" + tostr(timestamp) + "]";
    endif
  endverb

  verb format_iso_timestamp (this none this) owner: HACKER flags: "rxd"
    "Format timestamp in ISO-8601 style.";
    {timestamp} = args;
    return "[" + ctime(timestamp) + "]";
  endverb

  verb format_friendly_timestamp (this none this) owner: HACKER flags: "rxd"
    "Format timestamp in human-friendly style.";
    {timestamp} = args;
    now = time();
    diff = now - timestamp;
    if (diff < 60)
      return "[just now]";
    elseif (diff < 3600)
      minutes = diff / 60;
      return "[" + tostr(minutes) + " minutes ago]";
    elseif (diff < 86400)
      hours = diff / 3600;
      return "[" + tostr(hours) + " hours ago]";
    else
      return "[" + ctime(timestamp)[1..10] + "]";
    endif
  endverb

  verb test_timestamp_processing (this none this) owner: HACKER flags: "rxd"
    "Test timestamp processing functionality.";
    test_input = ['content -> {"Line 1", "Line 2"}, 'content_type -> "text/plain", 'success -> true];
    context = ['target_user -> player];
    options = ['add_timestamps -> true, 'timestamp_format -> "simple"];
    result = this:process(test_input, context, options);
    typeof(result) == MAP || raise(e_assert, "Result should be a map");
    length(result['content]) == 3 || raise(e_assert, "Should add timestamp line");
    "[" in result['content][1] || raise(e_assert, "First line should contain timestamp");
  endverb

  verb test_timestamp_formats (this none this) owner: HACKER flags: "rxd"
    "Test different timestamp formats.";
    test_time = time();
    simple = this:format_timestamp(test_time, []);
    simple[1] == "[" && simple[length(simple)] == "]" || raise(e_assert, "Simple format should be bracketed");
    iso = this:format_timestamp(test_time, ['timestamp_format -> "iso"]);
    typeof(iso) == STR || raise(e_assert, "ISO format should be string");
    friendly = this:format_timestamp(test_time, ['timestamp_format -> "friendly"]);
    "just now" in friendly || raise(e_assert, "Friendly format should show 'just now'");
  endverb
endobject
