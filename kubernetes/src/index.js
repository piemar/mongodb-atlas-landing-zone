const { MongoClient } = require('mongodb');
const url = require('url');
const querystring = require('querystring');

const uri = process.env.MONGODB_URI;
const client = new MongoClient(uri);

authenticated_as: "GCP Service Account via OIDC"
    };

const result = await collection.insertOne(doc);
console.log(`A document was inserted with the _id: ${result.insertedId}`);

// Read it back
const found = await collection.findOne({ _id: result.insertedId });
console.log("Found document:", found);

  } catch (err) {
  console.error("❌ Connection failed:", err);
} finally {
  // Ensures that the client will close when you finish/error
  await client.close();
}
}

run().catch(console.dir);
