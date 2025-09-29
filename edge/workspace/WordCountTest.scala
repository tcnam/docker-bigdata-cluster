import org.apache.spark.sql.SparkSession
import org.apache.hadoop.fs.{FileSystem, Path}

object WordCountTest {
  def main(args: Array[String]): Unit = {
    val outputPath = "/user/spark/demo_output"

    // Create Spark session
    val spark = SparkSession.builder
      .appName("WordCountTest")
      .getOrCreate()

    // Get Hadoop configuration from Spark
    val hadoopConf = spark.sparkContext.hadoopConfiguration
    val fs = FileSystem.get(hadoopConf)

    val outPath = new Path(outputPath)

    // If output already exists, delete it
    if (fs.exists(outPath)) {
      println(s"Output path $outputPath already exists, deleting...")
      fs.delete(outPath, true)
    } else {
      // Ensure parent dirs exist
      val parent = outPath.getParent
      if (!fs.exists(parent)) {
        println(s"Parent path ${parent.toString} does not exist, creating...")
        fs.mkdirs(parent)
      }
    }

    // Sample data
    val data = spark.sparkContext.parallelize(Seq(
      "hello spark",
      "hello world",
      "spark cluster test"
    ))

    // Word count
    val counts = data.flatMap(line => line.split(" "))
      .map(word => (word, 1))
      .reduceByKey(_ + _)

    // Print result to console
    counts.collect().foreach { case (word, count) =>
      println(s"$word: $count")
    }

    // Save result to HDFS
    counts.saveAsTextFile(outputPath)

    // Stop Spark
    spark.stop()
  }
}
