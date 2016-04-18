do
    
function run(msg, matches)
if matches[1] == "sh" and is_sudo(msg) then
return io.popen(matches[2]):read('*all')
end
end
return {
  patterns = {
    "^[/!$#](sh)(.*)",
     "^([sS][hH])(.*)",
  },
  run = run
}
end
