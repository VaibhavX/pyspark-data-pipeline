def main(event, context):
    print("Processing event:", event)
    return {"status" : "success", "records": len(event.get("records", []))}
