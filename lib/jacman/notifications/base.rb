#!/usr/bin/env ruby
# encoding: utf-8

# File: base.rb, created 13/12/14
# extracted from notification, created: 21/08/13
#
# (c) Michel Demazure & Kenji Lefevre

module JacintheManagement
  # Methods for e-subscriptions notification
  module Notifications
    # tiers for notification
    Tiers = Struct.new(:tiers_id, :name, :ranges, :mails, :drupal)

    # subscription parameters to be notified
    # noinspection RubyConstantNamingConvention
    ToBeNotified = Struct.new(:id, :revue, :year, :ref, :billing, :tiers_id)

    # reopening class
    class ToBeNotified
      # @return [String] report for mail
      def report
        "#{revue} (#{year}) ref:#{ref}"
      end
    end

    module Base
      # sql to extract tiers
      SQL_TIERS = SqlScriptFile.new('tiers_ip_infos').script

      # sql to count electronic subscriptions to be notified
      SQL_SUBSCRIPTION_NUMBER = SqlScriptFile.new('subscriptions_number_to_notify').script

      # sql to extract electronic subscriptions to be notified
      SQL_SUBSCRIPTIONS = SqlScriptFile.new('subscriptions_to_notify').script

      # sql to update base after notification
      SQL_UPDATE = SqlScriptFile.new('update_subscription_notified').script

      # @return [String] time stamp for files
      def self.time_stamp
        Time.now.strftime('%Y-%m-%d')
      end

      # FIXME:
      # tell JacintheD that subscription is notified
      # @param [STRING] subs_id subscription identity
      def self.update(subs_id)
        query = SQL_UPDATE
                .sub(/::abonnement_id::/, subs_id)
                .sub(/::time_stamp::/, time_stamp)
        if true #REAL
          Sql.query(JACINTHE_MODE, query) # this is real mode
        else
          puts "SQL : #{query}" # this is  demo mode
        end
      end

      # will be built and cached
      @all_jacinthe_tiers = nil
      @classified_notifications = nil

      ## base of all Jacinthe Tiers

      # @return [Array<Tiers>] list o/f all Jacinthe Tiers
      def self.build_jacinthe_tiers_list
        @all_jacinthe_tiers = []
        Sql.answer_to_query(JACINTHE_MODE, SQL_TIERS).drop(1).each do |line|
          items = line.split(TAB)
          parameters = format_items(items)
          @all_jacinthe_tiers[parameters[0]] = Tiers.new(*parameters)
        end
      end

      def self.all_jacinthe_tiers
        build_jacinthe_tiers_list unless @all_jacinthe_tiers
        @all_jacinthe_tiers
      end

      # @param [Array<String>] items split line form sql answer
      # @return [Array] parameters for Tiers struct
      def self.format_items(items)
        number = items[0].to_i
        name = items[2] == 'NULL' ? items[1] : items[2] + ' ' + items[1]
        ranges = clean_split('\\n', items[3])
        mails = clean_split(',', items[4].chomp)
        [number, name, ranges, mails]
      end

      # @param [String] sep separator
      # @param [String] string string to be split
      # @return [Array<String|nil>] formatted splitting of string
      def self.clean_split(sep, string)
        string.split(sep).delete_if { |item| item == 'NULL' }
      end

      # @param [Integer|#to_i] tiers_id tiers identification
      # @return [Tiers] this Tiers
      def self.find_tiers(tiers_id)
        all_jacinthe_tiers[tiers_id.to_i]
      end

      ## base of all pending notifications

      # count and return number of notifications to be done
      # @return [Integer] number of notifications to be done
      def self.notifications_number
        Sql.answer_to_query(JACINTHE_MODE, SQL_SUBSCRIPTION_NUMBER)[1].to_i
      end

      # FIXME: comment
      def self.all_notifications
        Sql.answer_to_query(JACINTHE_MODE, SQL_SUBSCRIPTIONS).drop(1).map do |line|
          items = line.chomp.split(Core::TAB)
          ToBeNotified.new(*items)
        end
      end

      # FIXME: comment
      def self.build_classified_notifications
        table = {}
        all_notifications.each do |item|
          key = [item.revue, item.year]
          (table[key] ||= []) << item
        end
        @classified_notifications = table
      end

      # FIXME:
      def self.classified_notifications
        build_classified_notifications unless @classified_notifications
        @classified_notifications
      end

      # FIXME
      def self.notification_categories
        classified_notifications.keys.sort
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME

  include JacintheManagement
  puts Notification::Base.notifications_number

end
