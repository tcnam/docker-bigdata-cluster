// ===== Simple Spark Test Script =====
import spark.implicits._
import org.apache.spark.sql.functions._
import org.apache.hadoop.fs.{FileSystem, Path}
import org.apache.hadoop.conf.Configuration

// Step 1: Create sample DataFrame
val data = Seq(
  ("Alice", "HR", 30),
  ("Bob", "IT", 25),
  ("Charlie", "IT", 35),
  ("David", "Finance", 40),
  ("Eva", "HR", 29)
)

val df = data.toDF("name", "department", "age")

println("=== Original Data ===")
df.show()

// Step 2: Do simple calculation
val avgAgeDF = df.groupBy("department")
  .agg(avg("age").alias("avg_age"))

println("=== Average Age by Department ===")
avgAgeDF.show()

// Step 3: Define HDFS output path
val outputPath = "hdfs://namenode:9000/user/spark/demo_input"
val hadoopConf = new Configuration()
val fs = FileSystem.get(hadoopConf)
val path = new Path(outputPath)

// Step 4: Check if path exists; if not, create it
if (!fs.exists(path)) {
  println(s"Creating HDFS directory: $outputPath")
  fs.mkdirs(path)
} else {
  println(s"Path already exists: $outputPath (will overwrite existing files)")
}

// Step 5: Save the DataFrame to HDFS (overwrite mode)
avgAgeDF.write.mode("overwrite").parquet(outputPath)

println(s"✅ Data successfully written to: $outputPath")
