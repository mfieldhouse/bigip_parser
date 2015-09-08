#Generic Parser
- Uses the parslet gem
- Parses lines of text, each line is parsed as :generic_line
- The parser can look for interesting lines. Lines starting 'mask ' are parsed as :mask. 
- Use as a starting point for parsing configuration files or other structured data