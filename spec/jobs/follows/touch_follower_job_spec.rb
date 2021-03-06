require "rails_helper"

RSpec.describe Follows::TouchFollowerJob, type: :job do
  include_examples "#enqueues_job", "touch_follower", 3

  describe "#perform_now" do
    context "with follow" do
      it "touches a follower" do
        timestamp = 1.day.ago
        user = create(:user, updated_at: timestamp, last_followed_at: timestamp)
        follow = create(:follow, follower: user)

        described_class.perform_now(follow.id)

        user.reload
        expect(user.updated_at).to be > timestamp
        expect(user.last_followed_at).to be > timestamp
      end
    end

    context "without follow" do
      it "does not break" do
        expect { described_class.perform_now(nil) }.not_to raise_error
      end
    end
  end
end
