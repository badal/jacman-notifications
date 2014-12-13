#!/usr/bin/env ruby
# encoding: utf-8

# File: notification.rb
# Created: 21/08/13
#
# (c) Michel Demazure & Kenji Lefevre

module JacintheManagement
  # Methods for e-subscriptions notification
  module Notifications
    # list to register Tiers with subscriptions but without mail
    @register = [['Id', 'Nom', 'Nombre', 'Plages ?'].join(Core::TAB)]

    # Register a line
    # @param [String] line line to be registered
    def self.register(line)
      @register << line
    end

    # sql to update base after notification
    SQL_UPDATE = SqlScriptFile.new('update_subscription_notified').script

    ##

    # build @to_be_notified_for and @tiers_list
    def self.extract_subscriptions_and_tiers
      @to_be_notified_for = []
      tiers_list = []
      p Base.classified_notifications.first

      Base.all_notifications.each do |tobenotified|
        tiers_id = tobenotified.tiers_id.to_i
        (@to_be_notified_for[tiers_id] ||= []) << tobenotified
        tiers_list << tiers_id
      end
      @tiers_list = tiers_list.sort.uniq
    end

    # @param [Integer|#to_i] tiers_id tiers identification
    # @return [Array<ToBeNotified] all subscriptions for this tiers
    def self.to_be_notified_for(tiers_id)
      extract_subscriptions_and_tiers unless @to_be_notified_for
      @to_be_notified_for[tiers_id.to_i]
    end

    # @return [Array<Integer>] list of tiers_id appearing in subscriptions
    def self.tiers_list
      extract_subscriptions_and_tiers unless @tiers_list
      @tiers_list
    end

    # @return [String] time stamp for files
    def self.time_stamp
      Time.now.strftime('%Y-%m-%d')
    end

    # tell JacintheD that subscription is notified
    # @param [STRING] subs_id subscription identity
    def self.update(subs_id)
      query = SQL_UPDATE
              .sub(/::abonnement_id::/, subs_id)
              .sub(/::time_stamp::/, time_stamp)
      if REAL
        Sql.query(JACINTHE_MODE, query) # this is real mode
      else
        puts "SQL : #{query}" # this is  demo mode
      end
    end

    # command to notify all subscriptions
    def self.notify_all
      number = Base.notifications_number
      if number > 0
        puts "#{number} notifications à faire"
        do_notify_all
        report_without_mail
      else
        puts 'Pas de notification à faire'
      end
    end

    # WARNING: HACK here to protect for invalid tiers
    # Notifier all subscriptions
    def self.do_notify_all
      number = tiers_list.size
      tiers_list.each do |tiers_id|
        done = Notifier.new(tiers_id).notify
        next if done
        number -= 1
        puts "notification impossible pour le tiers #{tiers_id}"
      end
      puts "#{number} mails(s) de notification envoyé(s)"
    end

    # Report how many users w/o mail
    def self.report_without_mail
      number = @register.size - 1
      save_register
      puts "<b>#{number} abonné(s) dépourvu(s) d'adresse mail</b>" if number > 0
    end

    NO_MAIL_FILE = File.join(Core::DATADIR, 'tiers_sans_mail.txt')

    # save the list of registered Tiers in a csv file
    def self.save_register
      File.open(NO_MAIL_FILE, 'w:utf-8') do |file|
        sum = 0
        @register.each do |line|
          file.puts(line)
          sum += line[2].to_i
        end
        file.puts(['', '', sum, ''].join(TAB))
      end
      puts "File #{NO_MAIL_FILE} saved"
    end

    # open in editor tiers without mail file
    def self.show_tiers_without_mail
      Utils.open_in_editor(NO_MAIL_FILE)
    end

    # @return [String] number of tiers without mail and number of subscriptions
    def self.tiers_without_mail
      lines = File.open(NO_MAIL_FILE, 'r:utf-8').readlines
      "#{lines.size - 2}/#{lines.last.split(TAB)[2]}"
    end
  end
end

if __FILE__ == $PROGRAM_NAME

  include JacintheManagement
  puts Notification.notifications_number

end
