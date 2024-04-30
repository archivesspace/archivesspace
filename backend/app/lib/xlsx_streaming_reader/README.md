# xlsx_streaming_reader

This is a gem for JRuby that parses large `.xlsx` files without using
all of your memory.

It's used like this:

```ruby
XLSXStreamingReader.new("/path/to/your/file.xlsx").each do |row|
  # `row` is an array containing a mix of Ruby strings, numbers, Boolean
  # and Time instances.
  #
  # Empty text cells come through as empty strings.
  #
  # Empty numeric cells come through as Ruby `nil`.
  #
  # Whole numeric values come through as `Integer`.  Everything else is `Float`.
  #
  # Each `row` can vary in length if your spreadsheet has trailing
  # empty cells in some rows.  As the name suggests,
  # `XLSXStreamingReader` doesn't read ahead, so if you need to pad
  # rows to a consistent length you'll need to handle that in your code.
end
```

If your file has multiple sheets, you can request them by index
(zero-offset) or name:

```ruby
XLSXStreamingReader.new("/path/to/your/file.xlsx").each(0) {...}
```

or

```ruby
XLSXStreamingReader.new("/path/to/your/file.xlsx").each("My Sheet") {...}
```

If the requested file isn't readable,
`XLSXStreamingReader::XLSXFileNotReadable` is thrown.
