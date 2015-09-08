#BIGIP Virtual Parser
- Uses the parslet gem
- Every line is parsed as :generic_line until the string 'virtual ' is reached. 
  The 'virtual { } configuration block and the options inside it are then parsed'
- Options inside the virtual server configuration are either known or unknown options
- Known options are currently: 'mask'
- All unknown options are parsed as:generic_option

##Development note - rule(:generic_line)
rule(:ignore) is used to skip over all uninteresting lines - those which 
are not 'virtual { }' configuration blocks

Do not use (:generic_line) anywhere else except inside ignore. This prevents
any confusion created by trying to use generic_line to match configuration options