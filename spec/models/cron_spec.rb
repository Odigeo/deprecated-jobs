require 'spec_helper'

describe CronJob do

  describe "CRON" do
    
    it "should have six components separated by spaces" do
      build(:cron_job, cron: "* * * * * *").should be_valid
      build(:cron_job, cron: " *  * * * *      *   ").should be_valid
      build(:cron_job, cron: "* * * * *").should_not be_valid
      build(:cron_job, cron: "* * * * * * *").should_not be_valid
      build(:cron_job, cron: "").should_not be_valid
      build(:cron_job, cron: {}).should_not be_valid
    end

    it "should not share substructure between instances" do
      build(:cron_job).cron_structure.should == build(:cron_job).cron_structure
      build(:cron_job).cron_structure.should_not be_equal build(:cron_job).cron_structure
    end

    it "should populate the seconds attribute when saved" do
      build(:cron_job).seconds.should == nil
      create(:cron_job).seconds.should_not == nil
    end

    it "should populate the minutes attribute when saved" do
      build(:cron_job).minutes.should == nil
      create(:cron_job).minutes.should_not == nil
    end

    it "should populate the hours attribute when saved" do
      build(:cron_job).hours.should == nil
      create(:cron_job).hours.should_not == nil
    end

    it "should populate the day_of_month attribute when saved" do
      build(:cron_job).day_of_month.should == nil
      create(:cron_job).day_of_month.should_not == nil
    end

    it "should populate the month attribute when saved" do
      build(:cron_job).month.should == nil
      create(:cron_job).month.should_not == nil
    end

    it "should populate the day_of_week attribute when saved" do
      build(:cron_job).day_of_week.should == nil
      create(:cron_job).day_of_week.should_not == nil
    end
  end


  describe "single number" do

  	it "of 1-10 for seconds should == [1, 10]" do
  	  create(:cron_job, cron: "0 1 2 3 4 5").seconds[:exactly].should == 0
  	end

  	it "of 1-10 for for minutes should == [1, 10]" do
  	  create(:cron_job, cron: "0 1 2 3 4 5").minutes[:exactly].should == 1
  	end

  	it "of 1-10 for for hours should == [1, 10]" do
  	  create(:cron_job, cron: "0 1 2 3 4 5").hours[:exactly].should == 2
  	end

  	it "of 1-10 for for day_of_month should == [1, 10]" do
  	  create(:cron_job, cron: "0 1 2 3 4 5").day_of_month[:exactly].should == 3
  	end

  	it "of 1-10 for for month should == [1, 10]" do
  	  create(:cron_job, cron: "0 1 2 3 4 5").month[:exactly].should == 4
  	end

  	it "of 1-4 for for day_of_week should == [1, 4]" do
  	  create(:cron_job, cron: "0 1 2 3 4 5").day_of_week[:exactly].should == 5
  	end
  end


  describe "range decomposition of *" do

  	it "for seconds should == [0, 59]" do
  	  create(:cron_job).seconds[:range].should == [0, 59]
  	end

  	it "for minutes should == [0, 59]" do
  	  create(:cron_job).minutes[:range].should == [0, 59]
  	end

  	it "for hours should == [0, 59]" do
  	  create(:cron_job).hours[:range].should == [0, 23]
  	end

  	it "for day_of_month should == [1, 31]" do
  	  create(:cron_job).day_of_month[:range].should == [1, 31]
  	end

  	it "for month should == [1, 12]" do
  	  create(:cron_job).month[:range].should == [1, 12]
  	end

  	it "for day_of_week should == [0, 6]" do
  	  create(:cron_job).day_of_week[:range].should == [0, 6]
  	end
  end


  describe "range decomposition" do

  	it "of 1-10 for seconds should == [1, 10]" do
  	  create(:cron_job, cron: "1-10 * * * * *").seconds[:range].should == [1, 10]
  	end

  	it "of 1-10 for for minutes should == [1, 10]" do
  	  create(:cron_job, cron: "* 1-10 * * * *").minutes[:range].should == [1, 10]
  	end

  	it "of 1-10 for for hours should == [1, 10]" do
  	  create(:cron_job, cron: "* * 1-10 * * *").hours[:range].should == [1, 10]
  	end

  	it "of 1-10 for for day_of_month should == [1, 10]" do
  	  create(:cron_job, cron: "* * * 1-10 * *").day_of_month[:range].should == [1, 10]
  	end

  	it "of 1-10 for for month should == [1, 10]" do
  	  create(:cron_job, cron: "* * * * 1-10 *").month[:range].should == [1, 10]
  	end

  	it "of 1-4 for for day_of_week should == [1, 4]" do
  	  create(:cron_job, cron: "* * * * * 1-4").day_of_week[:range].should == [1, 4]
  	end
  end


  describe "range decomposition with interval" do

  	it "of 3-59/15 for seconds should have a range of [3,59] and an interval of 15" do
  	  cj = create(:cron_job, cron: "3-59/15 * * * * *")
  	  cj.seconds[:range].should == [3, 59]
  	  cj.seconds[:interval].should == 15
  	end

  	it "of 3-59/15 for minutes should have a range of [3,59] and an interval of 15" do
  	  cj = create(:cron_job, cron: "* 3-59/15 * * * *")
  	  cj.minutes[:range].should == [3, 59]
  	  cj.minutes[:interval].should == 15
  	end

  	it "of 3-23/2 for for hours should have a range of [3, 23] and an interval of 2" do
  	  cj = create(:cron_job, cron: "* * 3-23/2 * * *")
  	  cj.hours[:range].should == [3, 23]
  	  cj.hours[:interval].should == 2
  	end

  	it "of 3-31/3 for for day_of_month should have a range of [3, 23] and an interval of 2" do
  	  cj = create(:cron_job, cron: "* * * 3-31/3 * *")
  	  cj.day_of_month[:range].should == [3, 31]
  	  cj.day_of_month[:interval].should == 3
  	end

  	it "of 2-12/3 for for month should have a range of [2, 12] and an interval of 3" do
  	  cj = create(:cron_job, cron: "* * * * 2-12/3 *")
  	  cj.month[:range].should == [2, 12]
  	  cj.month[:interval].should == 3
  	end

  	it "of 1-6/2 for for day_of_week should have a range of [1, 6] and an interval of 2" do
  	  cj = create(:cron_job, cron: "* * * * * 1-6/2")
  	  cj.day_of_week[:range].should == [1, 6]
  	  cj.day_of_week[:interval].should == 2
  	end
  end


end