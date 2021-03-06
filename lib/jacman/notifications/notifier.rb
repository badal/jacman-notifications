#!/usr/bin/env ruby
# encoding: utf-8

# File: notifier.rb
# Created: 21/08/13
#
# (c) Michel Demazure & Kenji Lefevre

module JacintheManagement
  module Notifications
    # class to carry all subscriptions to a given tiers
    class Notifier
      # file containing the model of notifications in french
      FRENCH_MODEL_FILE = File.join(Core::MODEL_DIR, 'french_model_mail.txt')
      # file containing the model of notifications in english
      ENGLISH_MODEL_FILE = File.join(Core::MODEL_DIR, 'english_model_mail.txt')
      # subject line of french mails
      FRENCH_SUBJECT = 'Notification de vos e-abonnements'
      # subject line of english mails
      ENGLISH_SUBJECT = 'Notification of yours e-subscriptions'

      # @param [Integer|#to_i] tiers_id tiers identification
      # @param [Array<ToBeNotified>] subscriptions to be notified for this Tiers
      # @param [Bool] mode whether mails have to be sent
      def initialize(tiers_id, subscriptions, mode)
        @tiers = Base.find_tiers(tiers_id)
        @subscriptions = subscriptions
        @mode = mode
      end

      # extract french and other addresses
      def extract_destinations
        destinations = @tiers.mails.group_by { |dest| dest.split('.').last == 'fr' }
        @french = destinations[true]
        @other = destinations[false]
      end

      # do notification for this tiers
      # @return [Bool] whether notifications were done
      def notify
        return false unless @tiers # invalid tiers_id
        extract_destinations
        if @french || @other
          done = notify_all_destinations
          say_notified if done && @mode
          done
        else # no mail
          register_tiers
          false
        end
      end

      # send all notification mails
      # @return [Bool] whether all possible notifications were done
      def notify_all_destinations
        done_french = !@french || notify_french(@french)
        done_other = !@other || notify_english(@other)
        done_french && done_other
      end

      # send notification in french to this address
      # @param [String] dest mail address
      def notify_french(dest)
        mail(dest, FRENCH_SUBJECT, mail_content(french_model_file))
      end

      # WARNING: DO NOT INLINE : Hack for collective
      # @return [Path] file containing the model in french
      def french_model_file
        FRENCH_MODEL_FILE
      end

      # send notification in english to this address
      # @param [String] dest mail address
      def notify_english(dest)
        mail(dest, ENGLISH_SUBJECT, mail_content(english_model_file))
      end

      # WARNING: DO NOT INLINE : Hack for collective
      # @return [Path] file containing the model in english
      def english_model_file
        ENGLISH_MODEL_FILE
      end

      # update database
      def say_notified
        @subscriptions.each { |sub| Base.update(sub.id) }
      end

      # @return [Array<String>] IP ranges (w/o comments)
      def ranges
        @tiers.ranges.reject { |line| line =~ /^\s*#/ }
      end

      # @return [Hash] substitutions to be made to model
      def substitutions
        { TIERS_ID: @tiers.tiers_id.to_s,
          NAME: @tiers.name,
          RANGES: ranges.join("\n"),
          MAILS: @tiers.mails.join("\n"),
          REVUES: @subscriptions.map(&:report).join("\n"),
          DRUPAL_ID: @tiers.drupal.to_s,
          DRUPAL_MAIL: @tiers.drupal_mail.to_s }
      end

      # @param [Path] file path to model file
      # @return [String] mail content for this tiers
      def mail_content(file)
        raw = File.read(file, encoding: 'utf-8')
        substitutions.each_pair do |key, value|
          raw.gsub!(key.to_s, value)
        end
        raw
      end

      # Registry this Tiers as a NotificationError
      def register_tiers
        ranges = !@tiers.ranges.empty?
        @subscriptions.each { |sub| Registry.register_error(sub, ranges) }
      end

      # send mail
      # @param [String] dest email address
      # @param [String] subject subject line of header
      # @param [String] content of mail
      def mail(dest, subject, content)
        mail_to_send = Utils::SmfMail.new(dest, subject, content)
        @mode ? mail_to_send.send : puts(mail_to_send.demo)
        true
      rescue StandardError => err
        puts report_error(err.message, dest)
        false
      end

      # @param [String] message erreur
      # @param [Array<String>] dest adresses de l'envoi
      # @return [Array<String>] report to be printed
      def report_error(message, dest)
        ['<b>Une erreur est survenue lors de l\'envoi au destinataire suivant :</b>',
         "Erreur : #{message}",
         "Tiers : #{@tiers.name}",
         "Id : #{@tiers.tiers_id}",
         "Adresses : #{dest.join(', ')}"]
      end
    end
  end
end
