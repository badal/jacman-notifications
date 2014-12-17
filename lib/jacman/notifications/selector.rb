#!/usr/bin/env ruby
# encoding: utf-8

# File: selector.rb
# Created: 21/08/13
#
# (c) Michel Demazure & Kenji Lefevre

module JacintheManagement
  # Methods for e-subscriptions notification
  module Notifications
    # FIXME:
    def self.notify_all(keys = Base.notification_categories)
      Selector.new(keys).notify_all
    end

    # FIXME:
    class Selector
      def initialize(keys)
        @keys = keys
        @report = []
        extract_subscriptions_and_tiers
      end

      ##
      # FIXME:
      # build @to_be_notified_for and @tiers_list
      def extract_subscriptions_and_tiers
        @to_be_notified_for = []
        tiers_list = []
        full_list = Base.classified_notifications
        @size = 0
        @keys.each do |key|
          full_list[key].each do |t_b_notified|
            @size += 1
            tiers_id = t_b_notified.tiers_id.to_i
            (@to_be_notified_for[tiers_id] ||= []) << t_b_notified
            tiers_list << tiers_id
          end
        end
        @tiers_list = tiers_list.sort.uniq
      end

      # @param [Integer|#to_i] tiers_id tiers identification
      # @return [Array<ToBeNotified] all subscriptions for this tiers
      def to_be_notified_for(tiers_id)
         @to_be_notified_for[tiers_id.to_i]
      end

      # @return [Array<Integer>] list of tiers_id appearing in subscriptions
      def tiers_list
        @tiers_list
      end

      # command to notify all subscriptions
      def notify_all
        if @size > 0
          @report << "#{@size} abonnement(s) à notifier"
          do_notify_all
          @report << Register.report_without_mail
        else
          @report << 'Pas de notification à faire'
        end
        @report
      end

      # WARNING: HACK here to protect for invalid tiers
      # Notifier all subscriptions
      def do_notify_all
        number = tiers_list.size
        @report << "#{number} mail(s) à envoyer"
        tiers_list.each do |tiers_id|
          subs = to_be_notified_for(tiers_id)
          done = Notifier.new(tiers_id, subs).notify
          next if done
          number -= 1
          @report << "notification impossible pour le tiers #{tiers_id}"
        end
        @report << "#{number} mails(s) de notification envoyé(s)"
      end
    end
  end
end
