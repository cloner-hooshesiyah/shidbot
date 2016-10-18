do

function run(msg, matches)

if is_sudo(msg) then
  send_document(get_receiver(msg), "./data/me/sudo.webp", ok_cb, false)
 elseif is_admin2(msg) then
  send_document(get_receiver(msg), "./data/me/admin.webp", ok_cb, false)
 elseif is_owner(msg) then
  send_document(get_receiver(msg), "./data/me/owner.webp", ok_cb, false)
 elseif is_momod2(msg) then
  send_document(get_receiver(msg), "./data/me/modiration.webp", ok_cb, false)
      end
  end

return {
patterns = {
"^[Ii]nfo$",

},
run = run
}

end
