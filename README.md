#BIGIP Virtual Parser
- Uses the parslet gem
- Every line is parsed as :generic_line until the string 'virtual ' is reached
- All known options inside the 'virtual { }' confiuguration block are parsed
- Any unknown options are parsed as:generic_option