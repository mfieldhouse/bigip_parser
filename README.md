#BIGIP Virtual Parser
- Uses the parslet gem
- Every line is parsed as :generic_line until the string 'virtual ' is reached. 
  The 'virtual { } configuration block and the options inside it are then 
  parsed'
- Options inside the virtual server configuration are either known or unknown 
  options
- Known options are currently: 'mask'
- All unknown options are parsed as:generic_option

##Output
Parsed output is formatted as an array of hashes containing an array of hashes.

 - The first array contains each of the virtual servers as hashes.
 - The second array contains each of the virtual server options as hashes.

##Development notes

###rule(:generic_line)
The :generic_line rule is used insiderule(:ignore). It skips over all 
uninteresting lines - those which are not 'virtual { }' configuration blocks 
but may contain special characters.

Special characters parsed by generic_line: '[!,:#'{}()*?]'
Special characters which break the parser:

 - Double backslash
 - Question mark

Do not use (:generic_line) anywhere else except inside ignore. This prevents
any confusion created by trying to use generic_line to match configuration 
options.

###End of file newline hack
When parsing the configuration file, the newline character is always on the 
end of every line, except for the last line where it may or may not be present.

To account for this, 'newline.maybe' has been 
added to rule(:generic_line) and rule(:virtual).