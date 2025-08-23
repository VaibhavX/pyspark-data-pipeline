'''
Sample script to run Great Expectations validation on data stored in AWS S3.
'''

from dotenv import load_dotenv
import boto3
import time
import os

import great_expectations as gx
from great_expectations.checkpoint import Checkpoint

context = gx.get_context()
YOUR_NAME = "testUser"
# Inspect the data context created
print(context)

# Create the data source to represent the data available in the MySQL DB
mysql_datasource = context.sources.add_sql(
    name=f"{YOUR_NAME}-db-datasource", connection_string="${MYSQL_CONNECTION_STRING}"
)

# Add a Data Asset to represent a discrete set of data
trips = mysql_datasource.add_table_asset(
    name=f"{YOUR_NAME}-trips", table_name="trips"
)

#Create batches to specify which data we want to validate
# Use the "vendor_id" column as splitter column
trips.add_splitter_column_value("vendor_id")

#Create a Batch Request
batch_request = trips.build_batch_request()

#Get the batches
batches = trips.get_batch_list_from_batch_request(batch_request=batch_request)

for batch in batches:
    print(batch.batch_spec)

#Create a batch request list for each of the batches
batch_request_list = [batch.batch_request for batch in batches]

#Add an expectation suite name to the context
expectation_suite_name = f"{YOUR_NAME}-trips-suite"
context.add_or_update_expectation_suite(expectation_suite_name=expectation_suite_name)

#Adding Validator - which validates the data against the expectations defined in the expectation suite
validator = context.get_validator(
    batch_request=batch_request_list, expectation_suite_name=expectation_suite_name)

#Setting the Expectation - descriptive language for specifying data quality conditions
validator.expect_column_values_to_not_be_null(column="pickup_datetime")
validator.expect_column_values_to_not_be_null(column="passenger_count")
validator.expect_column_values_to_be_between(column="congestion_surcharge", min_value=0, max_value=1000)

#Save the validation results
validator.save_expectation_suite(discard_failed_expectations=False)

'''
In Production environments, in the absence of manual validations, you have
to load into your new environment the expectation suite that you stored, 
and then pass it with your batch requests to a Checkpoint object. 
The checkpoint will automatically create a validator to validate your data against your expectations.'''

# Build the batch request
batch_request = trips.build_batch_request() 

# Create your batches using the batch_request from the previous cell
batches = trips.get_batch_list_from_batch_request(batch_request)

#Retrieve the expectation suite name
expectation_suite_name = context.list_expectation_suites()[0]

#Create the validation list 
validations = [
    {"batch_request": batch.batch_request, "expectation_suite_name": expectation_suite_name}
    for batch in batches
]

print(validations)

#Create a Checkpoint configuration that uses your Data Context

timestamp = time.time()
checkpoint_name = f"{YOUR_NAME}-checkpoint-trips-{timestamp}"

checkpoint = Checkpoint(
    name=checkpoint_name,
    run_name_template="trips %Y-%m-%d %H:%M:%S",
    data_context=context,
    expectation_suite_name=expectation_suite_name,
    validations=validations,
    action_list=[
        {
            "name": "store_validation_result",
            "action": {"class_name": "StoreValidationResultAction"},
        },
        {"name": "update_data_docs", "action": {"class_name": "UpdateDataDocsAction"}},        
    ],
)

#Add checkpoint to the context
context.add_or_update_checkpoint(checkpoint=checkpoint)

#Run the validations
checkpoint_result = checkpoint.run()

#Build Data Docs
context.build_data_docs()

#View the Results in the Data Docs
print(context.get_docs_sites_urls())

#End of script#
