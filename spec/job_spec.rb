require 'spec_helper'

describe Whenever::Job do

  def new_job(options = {})
    Whenever::Job.new options
  end
  
  it 'return the :at set when #at is called' do
    new_job(at: 'foo').at.should eq('foo')
  end

  it 'returns the :roles set when #roles is called' do
    new_job(roles: ['foo', 'bar']).roles.should eq(['foo', 'bar'])
  end
  
  it 'return whether it has a role from #has_role?' do
    new_job(roles: 'foo').should have_role('foo')
    new_job(roles: 'bar').should_not have_role('foo')
  end
  
  it 'substitutes the :task when #output is called' do
    new_job(template: ':task', task: 'abc123').output.should eq('abc123')
  end

  it 'substitutes the :path when #output is called' do
    new_job(template: ':path', path: 'foo').output.should eq('foo')
  end

  it 'substitutes the :path with the default Whenever.path if none is provided when #output is called' do
    Whenever.should_receive(:path).and_return('/my/path')
    new_job(template: ':path').output.should eq('/my/path')
  end
  
  it 'does not substitute parameters for which no value is set' do
    new_job(template: ':matching :world', matching: 'Hello').output.should eq('Hello :world')
  end
  
  it 'escapes the :path' do
    new_job(template: ':path', path: '/my/spacey path').output.should eq('/my/spacey\ path')
  end

  it 'escapes percent signs' do
    new_job(template: ':foo', foo: 'a % c').output.should eq('a \% c')
  end

  it 'assumes percent signs are not already escaped' do
    new_job(template: ':foo', foo: 'a \% c').output.should eq('a \\\% c')
  end
  
  it 'reject newlines' do
    expect{ new_job(template: ':foo', foo: "a \n b").output }.to raise_error(ArgumentError)
  end

  context 'quotes' do
    it 'output the :task if it is in single quotes' do
      new_job(template: "':task'", task: 'abc123').output.should eq(%q['abc123'])
    end
    
    it 'outputs the :task if it is in double quotes' do
      new_job(template: '":task"', task: 'abc123').output.should eq(%q["abc123"])                                                                      
    end

    it 'outputs escaped single quotes when it is wrapped in them' do
      new_job(template: "a ':foo' b", foo: "a ' b").output.should eq(%q[a 'a '\'' b' b])
    end

    it 'outputs escaped double quotes when it is wrapped in them' do
      new_job(template: 'a ":foo" b', foo: 'a " b').output.should eq(%q[a "a \" b" b])
    end
  end

  context 'job_templates' do
    it 'uses the job template' do
      new_job(template: ':task', task: 'foo', job_template: 'a :job b').output.should eq('a foo b')
    end

    it 'escapes single quotes' do
      new_job(template: "a ':task' b", task: "a ' b", job_template: "a ':job' b").output.should eq(%q[a 'a '\''a '\\''\\'\\'''\\'' b'\'' b' b])
    end
    
    it 'escape double quotes' do
      new_job(template: 'a ":task" b', task: 'a " b', job_template: 'a ":job" b').output.should eq(%q[a "a \"a \\\" b\" b" b])
    end
  end
end
