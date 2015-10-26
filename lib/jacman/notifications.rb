#!/usr/bin/env ruby
# encoding: utf-8

# File: notifications.rb
# Created: 13/12/2014
#
# (c) Michel Demazure <michel@demazure.com>

require_relative('notifications/version.rb')
require_relative('notifications/base.rb')
require_relative('notifications/registry.rb')
require_relative('notifications/selector.rb')
require_relative('notifications/notifier.rb')

module JacintheManagement
  module Notifications
    TAB = Core::TAB

    YEAR = Time.now.year
    MONTH = Time.now.month

    def self.filter(year)
      year.to_i >= ( MONTH <= 3 ? YEAR - 1 : YEAR )
    end
  end
end

