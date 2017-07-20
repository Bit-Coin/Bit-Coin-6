

class DevelopmentToolsController < ApplicationController

  def development_tools
  end

  def curious
    current_user.development_tools_info["curious"] = current_user.development_tools_info["curious"].to_i + 1
    current_user.save
  end
  def conscientious
    current_user.development_tools_info["conscientious"] = current_user.development_tools_info["conscientious"].to_i + 1
    current_user.save
  end

  def committed
    current_user.development_tools_info["committed"] = current_user.development_tools_info["committed"].to_i + 1
    current_user.save
  end
  def cooperative
    current_user.development_tools_info["cooperative"] = current_user.development_tools_info["cooperative"].to_i + 1
    current_user.save
  end
  def consistent
    current_user.development_tools_info["consistent"] = current_user.development_tools_info["consistent"].to_i + 1
    current_user.save
  end
  def management
    current_user.development_tools_info["management"] = current_user.development_tools_info["management"].to_i + 1
    current_user.save
  end
  def executive
    current_user.development_tools_info["executive"] = current_user.development_tools_info["executive"].to_i + 1
    current_user.save
  end
 end


