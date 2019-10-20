def unchanged()
	puts "not changed"
end

def changed(logger)
  logger.info "changed"

	"${TWITTER}" "@${Mizuho} IPアドレスの変更を検出しました\n${DATE}" "${Mizuho}"
	"${GMAIL}" "${TARGET_ADDRESS}" "IP Address Notification" "IP Address changed ${ip_latest} To ${ip_now} \n${DATE}" 

	"${SET_IP}" "${ip_now}"
	echo "${ip_now}" > "${ip_latest_file}"
end

def get_IP_failed()
	echo "failed"

	"${TWITTER}" "@${Mizuho} IPアドレスの変更に失敗しました\n${ip_now}\n${DATE}" "${Mizuho}"
	"${GMAIL}" "${TARGET_ADDRESS}" "IP Address Notification" "IP Address changed ${ip_latest} To ${ip_now} \n${DATE}" 
end
