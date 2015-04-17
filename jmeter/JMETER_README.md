# JMeter Test Group Template 

## Creating a test group:

  Load the file 'example_test_plan.jmx' into JMeter and make sure the following are true for the example to run successfully:
  
  * The backend is running on localhost port 4567
  
  * There is at least one repository, and its url is /repositories/2
  
The example will log in to the backend, store the session key as a JMeter variable, and make two basic requests, one of which will require a session key. 



