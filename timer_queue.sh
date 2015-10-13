export PATH="$HOME/packer/:$HOME/.rbenv/bin:/usr/local/bin:$PATH"
eval "$(rbenv init -)"
cd /Users/shim0mura/work/study/rails/havings
/Users/shim0mura/work/study/rails/havings/bin/bundle exec rails runner 'CheckTimerJob.perform_later'
# <string>/Users/shim0mura/work/study/rails/havings/bin/bundle</string>
# <string>exec rails runnner 'CheckTimerJob.perform_later'</string>
