require 'spec_helper'

describe CronJob do

  describe "CRON" do
    
    it "should have five components separated by spaces" do
      build(:cron_job, cron: "* * * * *").should be_valid
      build(:cron_job, cron: " *  * * *      *   ").should be_valid
      build(:cron_job, cron: "* * * *").should_not be_valid
      build(:cron_job, cron: "* * * * * *").should_not be_valid
      build(:cron_job, cron: "").should_not be_valid
      build(:cron_job, cron: {}).should_not be_valid
    end

    it "should not share substructure between instances" do
      build(:cron_job).cron_structure.should == build(:cron_job).cron_structure
      build(:cron_job).cron_structure.should_not be_equal build(:cron_job).cron_structure
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

  	it "of 1-10 for minutes should == [1, 10]" do
  	  create(:cron_job, cron: "1 2 3 4 5").minutes[:exactly].should == 1
  	end

  	it "of 1-10 for hours should == [1, 10]" do
  	  create(:cron_job, cron: "1 2 3 4 5").hours[:exactly].should == 2
  	end

  	it "of 1-10 for day_of_month should == [1, 10]" do
  	  create(:cron_job, cron: "1 2 3 4 5").day_of_month[:exactly].should == 3
  	end

  	it "of 1-10 for month should == [1, 10]" do
  	  create(:cron_job, cron: "1 2 3 4 5").month[:exactly].should == 4
  	end

  	it "of 1-4 for day_of_week should == [1, 4]" do
  	  create(:cron_job, cron: "1 2 3 4 5").day_of_week[:exactly].should == 5
  	end
  end


  describe "range decomposition of *" do

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

  	it "of 1-10 for minutes should == [1, 10]" do
  	  create(:cron_job, cron: "1-10 * * * *").minutes[:range].should == [1, 10]
  	end

  	it "of 1-10 for hours should == [1, 10]" do
  	  create(:cron_job, cron: "* 1-10 * * *").hours[:range].should == [1, 10]
  	end

  	it "of 1-10 for day_of_month should == [1, 10]" do
  	  create(:cron_job, cron: "* * 1-10 * *").day_of_month[:range].should == [1, 10]
  	end

  	it "of 1-10 for month should == [1, 10]" do
  	  create(:cron_job, cron: "* * * 1-10 *").month[:range].should == [1, 10]
  	end

  	it "of 1-4 for day_of_week should == [1, 4]" do
  	  create(:cron_job, cron: "* * * * 1-4").day_of_week[:range].should == [1, 4]
  	end
  end


  describe "range decomposition with interval" do

  	it "of 3-59/15 for minutes should have a range of [3,59] and an interval of 15" do
  	  cj = create(:cron_job, cron: "3-59/15 * * * *")
  	  cj.minutes[:range].should == [3, 59]
  	  cj.minutes[:interval].should == 15
  	end

  	it "of 3-23/2 for hours should have a range of [3, 23] and an interval of 2" do
  	  cj = create(:cron_job, cron: "* 3-23/2 * * *")
  	  cj.hours[:range].should == [3, 23]
  	  cj.hours[:interval].should == 2
  	end

  	it "of 3-31/3 for day_of_month should have a range of [3, 23] and an interval of 2" do
  	  cj = create(:cron_job, cron: "* * 3-31/3 * *")
  	  cj.day_of_month[:range].should == [3, 31]
  	  cj.day_of_month[:interval].should == 3
  	end

  	it "of 2-12/3 for month should have a range of [2, 12] and an interval of 3" do
  	  cj = create(:cron_job, cron: "* * * 2-12/3 *")
  	  cj.month[:range].should == [2, 12]
  	  cj.month[:interval].should == 3
  	end

  	it "of 1-6/2 for day_of_week should have a range of [1, 6] and an interval of 2" do
  	  cj = create(:cron_job, cron: "* * * * 1-6/2")
  	  cj.day_of_week[:range].should == [1, 6]
  	  cj.day_of_week[:interval].should == 2
  	end
  end


  describe "range decomposition of * with interval" do

  	it "of */15 for minutes should parse correctly" do
  	  cj = create(:cron_job, cron: "*/15 * * * *")
  	  cj.minutes[:range].should == [0, 59]
  	  cj.minutes[:interval].should == 15
  	end

  	it "of */2 for hours should parse correctly" do
  	  cj = create(:cron_job, cron: "* */2 * * *")
  	  cj.hours[:range].should == [0, 23]
  	  cj.hours[:interval].should == 2
  	end

  	it "of */3 for day_of_month should parse correctly" do
  	  cj = create(:cron_job, cron: "* * */3 * *")
  	  cj.day_of_month[:range].should == [1, 31]
  	  cj.day_of_month[:interval].should == 3
  	end

  	it "of */3 for month should parse correctly" do
  	  cj = create(:cron_job, cron: "* * * */3 *")
  	  cj.month[:range].should == [1, 12]
  	  cj.month[:interval].should == 3
  	end

  	it "of */2 for day_of_week should parse correctly" do
  	  cj = create(:cron_job, cron: "* * * * */2")
  	  cj.day_of_week[:range].should == [0, 6]
  	  cj.day_of_week[:interval].should == 2
  	end
  end


  describe "lists of 1,4,6" do

  	it "for minutes should == [1, 4, 6]" do
  	  create(:cron_job, cron: "1,4,6 * * * *").minutes[:member].should == [1, 4, 6]
  	end

  	it "for hours should == [1, 4, 6]" do
  	  create(:cron_job, cron: "* 1,4,6 * * *").hours[:member].should == [1, 4, 6]
  	end

  	it "for day_of_month should == [1, 4, 6]" do
  	  create(:cron_job, cron: "* * 1,4,6 * *").day_of_month[:member].should == [1, 4, 6]
  	end

  	it "of 1-10 for for month should == [1, 4, 6]" do
  	  create(:cron_job, cron: "* * * 1,4,6 *").month[:member].should == [1, 4, 6]
  	end

  	it "of 1-4 for for day_of_week should == [1, 4, 6]" do
  	  create(:cron_job, cron: "* * * * 1,4,6").day_of_week[:member].should == [1, 4, 6]
  	end
  end


  it "should parse JAN, FEB, MAR, etc in months" do
  	create(:cron_job, cron: "* * * NOV,DEC *").month[:member].should == [11, 12]
  	create(:cron_job, cron: "* * * JAN *").month[:exactly].should == 1
  	create(:cron_job, cron: "* * * FEB-DEC/2 *").month[:range].should == [2, 12]
  	create(:cron_job, cron: "* * * FEB-DEC/2 *").month[:interval].should == 2
  end

  it "should parse MON, TUE, WED, etc in day_of_week" do
  	create(:cron_job, cron: "* * * * TUE,FRI").day_of_week[:member].should == [2, 5]
  	create(:cron_job, cron: "* * * * SUN").day_of_week[:exactly].should == 0
  	create(:cron_job, cron: "* * * * MON-FRI/2").day_of_week[:range].should == [1, 5]
  	create(:cron_job, cron: "* * * * SUN-FRI/2").day_of_week[:interval].should == 2
  end

  it "should not parse month names except in months" do
    cj = build(:cron_job, cron: "MAY * * * *")
    cj.should_not be_valid
    cj.errors.messages.should == {:cron=>["minutes value 'MAY' is unrecognized"]}
  end

  it "should not parse weekday names except in day_of_week" do
    cj = build(:cron_job, cron: "* * WED * *")
    cj.should_not be_valid
    cj.errors.messages.should == {:cron=>["day_of_month value 'WED' is unrecognized"]}
  end

  it "should not parse single out of range values" do
    cj = build(:cron_job, cron: "* * * * 100")
    cj.should_not be_valid
    cj.errors.messages.should == {:cron=>["day_of_week value '100' is out of range"]}
  end

  it "should not parse ranges containing out of range values" do
    cj = build(:cron_job, cron: "* * * 0-100 *")
    cj.should_not be_valid
    cj.errors.messages.should == {:cron=>["month range value '0-100' starts out of range", 
                                          "month range value '0-100' ends out of range"]}
  end

  it "should not parse ranges with intervals containing out of range values" do
    cj = build(:cron_job, cron: "* * 10-40/2 * *")
    cj.should_not be_valid
    cj.errors.messages.should == {:cron=>["day_of_month range value '10-40/2' ends out of range"]}
  end

  it "should not parse ranges where the end is less than the start" do
    cj = build(:cron_job, cron: "* * * DEC-JAN *")
    cj.should_not be_valid
    cj.errors.messages.should == {:cron=>["month range value 'DEC-JAN' ends before it starts"]}
  end

  it "should not parse lists with elements containing out of range values" do
    cj = build(:cron_job, cron: "* 10,20,30,40 * * *")
    cj.should_not be_valid
    cj.errors.messages.should == {:cron=>["hours list '10,20,30,40' contains out of range element(s)"]}
  end


  describe "aliases" do

    it "should translate @hourly to 0 * * * *" do
      cj = create :cron_job, cron: "@hourly"
      cj.cron.should == "@hourly"
      cj.cron_structure.should == [{:exactly=>0}, {:range=>[0, 23]}, {:range=>[1, 31]}, 
                                   {:range=>[1, 12]}, {:range=>[0, 6]}]
    end

    it "should translate @daily to 0 0 * * *" do
      cj = create :cron_job, cron: "@daily"
      cj.cron.should == "@daily"
      cj.cron_structure.should == [{:exactly=>0}, {:exactly=>0}, {:range=>[1, 31]}, 
                                   {:range=>[1, 12]}, {:range=>[0, 6]}]
    end

    it "should translate @weekly to 0 0 * * 0" do
      cj = create :cron_job, cron: "@weekly"
      cj.cron.should == "@weekly"
      cj.cron_structure.should == [{:exactly=>0}, {:exactly=>0}, {:range=>[1, 31]}, 
                                   {:range=>[1, 12]}, {:exactly=>0}]
    end

    it "should translate @monthly to 0 0 1 * *" do
      cj = create :cron_job, cron: "@monthly"
      cj.cron.should == "@monthly"
      cj.cron_structure.should == [{:exactly=>0}, {:exactly=>0}, {:exactly=>1}, 
                                   {:range=>[1, 12]}, {:range=>[0, 6]}]
    end

    it "should translate @yearly to 0 0 1 1 *" do
      cj = create :cron_job, cron: "@yearly"
      cj.cron.should == "@yearly"
      cj.cron_structure.should == [{:exactly=>0}, {:exactly=>0}, {:exactly=>1}, 
                                   {:exactly=>1}, {:range=>[0, 6]}]
    end

    it "should translate @annually to 0 0 1 1 *" do
      cj = create :cron_job, cron: "@annually"
      cj.cron.should == "@annually"
      cj.cron_structure.should == [{:exactly=>0}, {:exactly=>0}, {:exactly=>1}, 
                                   {:exactly=>1}, {:range=>[0, 6]}]
    end

  end

end