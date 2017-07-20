class Admin::MessagesController < AdminController

  def dead_letters
    @messages = Message.dead.order(created_at: :desc)
  end
end
