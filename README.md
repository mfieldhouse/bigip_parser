#BIGIP Virtual Parser
- Uses the parslet gem
- Every line is parsed as :generic_line until the string 'virtual ' is reached
- All known options inside the 'virtual { }' configuration block are parsed
- Any unknown options are parsed as:generic_option

##rule(:generic_line)
rule(:ignore) is used to skip over all uninteresting lines - those which 
are not 'virtual { }' configuration blocks

Do not use (:generic_line) anywhere else except inside ignore. This prevents
any confusion created by trying to use generic_line to match configuration options