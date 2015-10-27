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
    # last month for showing previous year in GUI
    LAST_MONTH = 3 # March

    # @param [String|Fixnum] year year to test
    # @return [Bool] whether year is to be shown in GUI
    def self.filter(year)
      year.to_i >= ( MONTH <= LAST_MONTH ? YEAR - 1 : YEAR )
    end
  end
end

