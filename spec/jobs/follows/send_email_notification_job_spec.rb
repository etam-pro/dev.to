require "rails_helper"

RSpec.describe Follows::SendEmailNotificationJob, type: :job do
  include_examples "#enqueues_job", "send_follow_email_notification", 3

  describe "#perform_now" do
    context "with follow" do
      let_it_be(:user) { create(:user) }
      let_it_be(:user2) { create(:user) }
      let_it_be(:follow) { create(:follow, follower: user, followable: user2) }
      let(:mailer) { double }

      before do
        deliverer = double
        allow(deliverer).to receive(:deliver)
        allow(mailer).to receive(:new_follower_email).and_return(deliverer)
      end

      it "sends a new_follower_email" do
        user2.update_column(:email_follower_notifications, true)

        described_class.new(follow.id, mailer).perform_now

        expect(mailer).to have_received(:new_follower_email).once
      end

      it "doesn't create an EmailMessage if it already exists" do
        subject = "#{user.username} followed you on dev.to"
        EmailMessage.create!(user_id: user2.id, sent_at: Time.current, subject: subject)

        described_class.new(follow.id, mailer).perform_now

        expect(mailer).not_to have_received(:new_follower_email)
      end

      it "doesn't send an email if user has disabled notifications" do
        user2.update_column(:email_follower_notifications, false)

        expect(mailer).not_to have_received(:new_follower_email)
      end
    end

    context "without follow" do
      it "does not break" do
        expect { described_class.perform_now(nil) }.not_to raise_error
      end
    end
  end
end
