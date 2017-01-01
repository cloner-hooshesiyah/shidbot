do

function run(msg, matches)
  return [[
  👥Sudoers of Bot : 
  🔭 @anony_bax 245846142 👥
    برای خرید گروه به سودو در ایدی بالا مراجعه کنید گُلاے من 
   
 
  ]]

  end
return {
  description = "shows sudoers", 
  usage = "!sudoers : return sudousers",
  patterns = {
    "^SUDOERS$",
    "^/sudoers$",
    "^!sudoers$",
    "^sudoers$",
    "^sd$"
  },
  run = run
}
end
