do

function run(msg, matches)
  return [[
  👥Sudoers of Noosspeed : 
  🔭 @anony_bax 245846142 👥
   
 
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
