# m = Mail.new "Received: from localhost.localdomain (Unknown [127.0.0.1])
#   by tools.mailflowmonitoring.com (Haraka/2.8.21) with ESMTPS id B84ED58A-996F-4504-9CC8-7EB4644469A9.1
#   envelope-from <monitor@tools.mailflowmonitoring.com>
#   (version=TLSv1/SSLv3 cipher=ECDHE-RSA-AES128-GCM-SHA256 verify=FAIL);
#   Thu, 01 Nov 2018 00:08:56 +0500
# Date: Thu, 01 Nov 2018 00:08:56 +0500
# From: rr@r.com
# To: monitor@tools.mailflowmonitoring.com
# Message-ID: <1541012936160.8405.EMail_Client@[127.0.0.1]>
# Subject: MailFlowMonitor Ping - 175df22f-ce0b-40f5-844c-90499b45c824
# Mime-Version: 1.0
# Content-Type: text/plain;
#  charset=UTF-8
# Content-Transfer-Encoding: 7bit

# This is an auto-generated email. Please don't reply to it.
# "

# Mikel Lindsaar <mikel@test.lindsaar.net>, ada@test.lindsaar.net

m = Mail.new "To: Mikel Lindsaar <mikel@test.lindsaar.net>, ada@test.lindsaar.net

This is an auto-generated email. Please don't reply to it.
"
puts m.to.inspect
