module ResqueWeb
  class ApplicationController < ::AdminController
    protect_from_forgery
    before_filter :set_subtabs

    helper :all

    def self.subtabs(*tab_names)
      return defined?(@subtabs) ? @subtabs : [] if tab_names.empty?
      @subtabs = tab_names
    end

    def set_subtabs(subtabs = self.class.subtabs)
      @subtabs = subtabs
    end

  end
end
