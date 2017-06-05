module Lita
  module Commands

    class AccountSummary

      def name
        'account-summary'
      end

      def run(robot, target, gateway, opts = {})
        msg = build_msg(gateway)
        robot.send_message(target, msg)
      end

      private

      def build_msg(gateway)
        data = get_account_data(gateway)

        msg = "GSuite Account Summary - incorrect or out-of-date details can be updated at https://admin.google.com\n\n"
        data.each do |label, value|
          msg += "#{label}: #{value}\n"
        end
        msg
      end

      def get_account_data(gateway)
        account = gateway.account_summary
        {
          "ID" => account.id,
          "Alternate Email" => account.alternate_email,
          "Created At" => account.created_at.iso8601,
          "Primary Domain" => account.primary_domain,
          "Language" => account.language,
          "Phone Number" => account.phone_number,
          "Address" => account.address,
          "Contact Name" => account.contact_name,
        }.reject { |item|
          item.nil? || item == ""
        }
      end

    end
  end
end
