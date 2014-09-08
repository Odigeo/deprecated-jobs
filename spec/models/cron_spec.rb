require 'spec_helper'

describe CronJob, :type => :model do

  describe "CRON" do
    
    it "should have five components separated by spaces" do
      expect(build(:cron_job, cron: "* * * * *")).to be_valid
      expect(build(:cron_job, cron: " *  * * *      *   ")).to be_valid
      expect(build(:cron_job, cron: "* * * *")).not_to be_valid
      expect(build(:cron_job, cron: "* * * * * *")).not_to be_valid
      expect(build(:cron_job, cron: "")).not_to be_valid
      expect(build(:cron_job, cron: {})).not_to be_valid
    end

    it "should not share substructure between instances" do
      expect(build(:cron_job).cron_structure).to eq build(:cron_job).cron_structure
      expect(build(:cron_job).cron_structure).not_to be_equal build(:cron_job).cron_structure
    end

    it "should populate the minutes attribute when saved" do
      expect(build(:cron_job).minutes).to eq nil
      expect(create(:cron_job).minutes).not_to eq nil
    end

    it "should populate the hours attribute when saved" do
      expect(build(:cron_job).hours).to eq nil
      expect(create(:cron_job).hours).not_to eq nil
    end

    it "should populate the day_of_month attribute when saved" do
      expect(build(:cron_job).day_of_month).to eq nil
      expect(create(:cron_job).day_of_month).not_to eq nil
    end

    it "should populate the month attribute when saved" do
      expect(build(:cron_job).month).to eq nil
      expect(create(:cron_job).month).not_to eq nil
    end

    it "should populate the day_of_week attribute when saved" do
      expect(build(:cron_job).day_of_week).to eq nil
      expect(create(:cron_job).day_of_week).not_to eq nil
    end
  end


  describe "single number" do

  	it "of 1-10 for minutes should == [1, 10]" do
  	  expect(create(:cron_job, cron: "1 2 3 4 5").minutes["exactly"]).to eq 1
  	end

  	it "of 1-10 for hours should == [1, 10]" do
  	  expect(create(:cron_job, cron: "1 2 3 4 5").hours["exactly"]).to eq 2
  	end

  	it "of 1-10 for day_of_month should == [1, 10]" do
  	  expect(create(:cron_job, cron: "1 2 3 4 5").day_of_month["exactly"]).to eq 3
  	end

  	it "of 1-10 for month should == [1, 10]" do
  	  expect(create(:cron_job, cron: "1 2 3 4 5").month["exactly"]).to eq 4
  	end

  	it "of 1-4 for day_of_week should == [1, 4]" do
  	  expect(create(:cron_job, cron: "1 2 3 4 5").day_of_week["exactly"]).to eq 5
  	end
  end


  describe "range decomposition of *" do

  	it "for minutes should == true" do
  	  expect(create(:cron_job).minutes).to eq true
  	end

  	it "for hours should == true" do
  	  expect(create(:cron_job).hours).to eq true
  	end

  	it "for day_of_month should == true" do
  	  expect(create(:cron_job).day_of_month).to eq true
  	end

  	it "for month should == true" do
  	  expect(create(:cron_job).month).to eq true
  	end

  	it "for day_of_week should == true" do
  	  expect(create(:cron_job).day_of_week).to eq true
  	end
  end


  describe "range decomposition" do

  	it "of 1-10 for minutes should == [1, 10]" do
  	  expect(create(:cron_job, cron: "1-10 * * * *").minutes["range"]).to eq [1, 10]
  	end

  	it "of 1-10 for hours should == [1, 10]" do
  	  expect(create(:cron_job, cron: "* 1-10 * * *").hours["range"]).to eq [1, 10]
  	end

  	it "of 1-10 for day_of_month should == [1, 10]" do
  	  expect(create(:cron_job, cron: "* * 1-10 * *").day_of_month["range"]).to eq [1, 10]
  	end

  	it "of 1-10 for month should == [1, 10]" do
  	  expect(create(:cron_job, cron: "* * * 1-10 *").month["range"]).to eq [1, 10]
  	end

  	it "of 1-4 for day_of_week should == [1, 4]" do
  	  expect(create(:cron_job, cron: "* * * * 1-4").day_of_week["range"]).to eq [1, 4]
  	end
  end


  describe "range decomposition with interval" do

  	it "of 3-59/15 for minutes should have a range of [3,59] and an interval of 15" do
  	  cj = create(:cron_job, cron: "3-59/15 * * * *")
  	  expect(cj.minutes["range"]).to eq [3, 59]
  	  expect(cj.minutes["interval"]).to eq 15
  	end

  	it "of 3-23/2 for hours should have a range of [3, 23] and an interval of 2" do
  	  cj = create(:cron_job, cron: "* 3-23/2 * * *")
  	  expect(cj.hours["range"]).to eq [3, 23]
  	  expect(cj.hours["interval"]).to eq 2
  	end

  	it "of 3-31/3 for day_of_month should have a range of [3, 23] and an interval of 2" do
  	  cj = create(:cron_job, cron: "* * 3-31/3 * *")
  	  expect(cj.day_of_month["range"]).to eq [3, 31]
  	  expect(cj.day_of_month["interval"]).to eq 3
  	end

  	it "of 2-12/3 for month should have a range of [2, 12] and an interval of 3" do
  	  cj = create(:cron_job, cron: "* * * 2-12/3 *")
  	  expect(cj.month["range"]).to eq [2, 12]
  	  expect(cj.month["interval"]).to eq 3
  	end

  	it "of 1-6/2 for day_of_week should have a range of [1, 6] and an interval of 2" do
  	  cj = create(:cron_job, cron: "* * * * 1-6/2")
  	  expect(cj.day_of_week["range"]).to eq [1, 6]
  	  expect(cj.day_of_week["interval"]).to eq 2
  	end
  end


  describe "range decomposition of * with interval" do

  	it "of */15 for minutes should parse correctly" do
  	  cj = create(:cron_job, cron: "*/15 * * * *")
  	  expect(cj.minutes["range"]).to eq [0, 59]
  	  expect(cj.minutes["interval"]).to eq 15
  	end

  	it "of */2 for hours should parse correctly" do
  	  cj = create(:cron_job, cron: "* */2 * * *")
  	  expect(cj.hours["range"]).to eq [0, 23]
  	  expect(cj.hours["interval"]).to eq 2
  	end

  	it "of */3 for day_of_month should parse correctly" do
  	  cj = create(:cron_job, cron: "* * */3 * *")
  	  expect(cj.day_of_month["range"]).to eq [1, 31]
  	  expect(cj.day_of_month["interval"]).to eq 3
  	end

  	it "of */3 for month should parse correctly" do
  	  cj = create(:cron_job, cron: "* * * */3 *")
  	  expect(cj.month["range"]).to eq [1, 12]
  	  expect(cj.month["interval"]).to eq 3
  	end

  	it "of */2 for day_of_week should parse correctly" do
  	  cj = create(:cron_job, cron: "* * * * */2")
  	  expect(cj.day_of_week["range"]).to eq [0, 6]
  	  expect(cj.day_of_week["interval"]).to eq 2
  	end
  end


  describe "lists of 1,4,6" do

  	it "for minutes should == [1, 4, 6]" do
  	  expect(create(:cron_job, cron: "1,4,6 * * * *").minutes["member"]).to eq [1, 4, 6]
  	end

  	it "for hours should == [1, 4, 6]" do
  	  expect(create(:cron_job, cron: "* 1,4,6 * * *").hours["member"]).to eq [1, 4, 6]
  	end

  	it "for day_of_month should == [1, 4, 6]" do
  	  expect(create(:cron_job, cron: "* * 1,4,6 * *").day_of_month["member"]).to eq [1, 4, 6]
  	end

  	it "of 1-10 for for month should == [1, 4, 6]" do
  	  expect(create(:cron_job, cron: "* * * 1,4,6 *").month["member"]).to eq [1, 4, 6]
  	end

  	it "of 1-4 for for day_of_week should == [1, 4, 6]" do
  	  expect(create(:cron_job, cron: "* * * * 1,4,6").day_of_week["member"]).to eq [1, 4, 6]
  	end
  end


  it "should parse JAN, FEB, MAR, etc in months" do
  	expect(create(:cron_job, cron: "* * * NOV,DEC *").month["member"]).to eq [11, 12]
  	expect(create(:cron_job, cron: "* * * JAN *").month["exactly"]).to eq 1
  	expect(create(:cron_job, cron: "* * * FEB-DEC/2 *").month["range"]).to eq [2, 12]
  	expect(create(:cron_job, cron: "* * * FEB-DEC/2 *").month["interval"]).to eq 2
  end

  it "should parse MON, TUE, WED, etc in day_of_week" do
  	expect(create(:cron_job, cron: "* * * * TUE,FRI").day_of_week["member"]).to eq [2, 5]
  	expect(create(:cron_job, cron: "* * * * SUN").day_of_week["exactly"]).to eq 0
  	expect(create(:cron_job, cron: "* * * * MON-FRI/2").day_of_week["range"]).to eq [1, 5]
  	expect(create(:cron_job, cron: "* * * * SUN-FRI/2").day_of_week["interval"]).to eq 2
  end

  it "should not parse month names except in months" do
    cj = build(:cron_job, cron: "MAY * * * *")
    expect(cj).not_to be_valid
    expect(cj.errors.messages).to eq({:cron=>["minutes value 'MAY' is unrecognized"]})
  end

  it "should not parse weekday names except in day_of_week" do
    cj = build(:cron_job, cron: "* * WED * *")
    expect(cj).not_to be_valid
    expect(cj.errors.messages).to eq({:cron=>["day_of_month value 'WED' is unrecognized"]})
  end

  it "should not parse single out of range values" do
    cj = build(:cron_job, cron: "* * * * 100")
    expect(cj).not_to be_valid
    expect(cj.errors.messages).to eq({:cron=>["day_of_week value '100' is out of range"]})
  end

  it "should not parse ranges containing out of range values" do
    cj = build(:cron_job, cron: "* * * 0-100 *")
    expect(cj).not_to be_valid
    expect(cj.errors.messages).to eq({:cron=>["month range value '0-100' starts out of range", 
                                          "month range value '0-100' ends out of range"]})
  end

  it "should not parse ranges with intervals containing out of range values" do
    cj = build(:cron_job, cron: "* * 10-40/2 * *")
    expect(cj).not_to be_valid
    expect(cj.errors.messages).to eq({:cron=>["day_of_month range value '10-40/2' ends out of range"]})
  end

  it "should not parse ranges where the end is less than the start" do
    cj = build(:cron_job, cron: "* * * DEC-JAN *")
    expect(cj).not_to be_valid
    expect(cj.errors.messages).to eq({:cron=>["month range value 'DEC-JAN' ends before it starts"]})
  end

  it "should not parse lists with elements containing out of range values" do
    cj = build(:cron_job, cron: "* 10,20,30,40 * * *")
    expect(cj).not_to be_valid
    expect(cj.errors.messages).to eq({:cron=>["hours list '10,20,30,40' contains out of range element(s)"]})
  end


  describe "aliases" do

    it "should translate @hourly to 0 * * * *" do
      cj = create :cron_job, cron: "@hourly"
      expect(cj.cron).to eq "@hourly"
      expect(cj.cron_structure).to eq [{"exactly"=>0}, true, true, true, true]
    end

    it "should translate @daily to 0 0 * * *" do
      cj = create :cron_job, cron: "@daily"
      expect(cj.cron).to eq "@daily"
      expect(cj.cron_structure).to eq [{"exactly"=>0}, {"exactly"=>0}, true, true, true]
    end

    it "should translate @weekly to 0 0 * * 0" do
      cj = create :cron_job, cron: "@weekly"
      expect(cj.cron).to eq "@weekly"
      expect(cj.cron_structure).to eq [{"exactly"=>0}, {"exactly"=>0}, true, true, {"exactly"=>0}]
    end

    it "should translate @monthly to 0 0 1 * *" do
      cj = create :cron_job, cron: "@monthly"
      expect(cj.cron).to eq "@monthly"
      expect(cj.cron_structure).to eq [{"exactly"=>0}, {"exactly"=>0}, {"exactly"=>1}, true, true]
    end

    it "should translate @yearly to 0 0 1 1 *" do
      cj = create :cron_job, cron: "@yearly"
      expect(cj.cron).to eq "@yearly"
      expect(cj.cron_structure).to eq [{"exactly"=>0}, {"exactly"=>0}, {"exactly"=>1}, 
                                       {"exactly"=>1}, true]
    end

    it "should translate @annually to 0 0 1 1 *" do
      cj = create :cron_job, cron: "@annually"
      expect(cj.cron).to eq "@annually"
      expect(cj.cron_structure).to eq [{"exactly"=>0}, {"exactly"=>0}, {"exactly"=>1}, 
                                       {"exactly"=>1}, true]
    end

  end

end