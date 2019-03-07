package scala.etl

import org.apache.log4j.LogManager
import org.apache.spark.sql.{SQLContext, SparkSession}


object SparkRunner {

  def main(args: Array[String]): Unit = {

    val log = LogManager.getRootLogger

    log.info("**********Spark EXECUTION STARTED**********")

    val spark = SparkSession.builder()
      .master("local")
      .appName("Spark CSV Reader")
      .getOrCreate

    val shopsDF = spark.read.options(Map("inferSchema"->"true","sep"->",","header"->"true")).csv(
      "src/main/resources/shops_GENERATED.csv"
    )

    val ordersDF = spark.read.options(Map("inferSchema"->"true","sep"->",","header"->"true")).csv(
      "src/main/resources/orders_GENERATED.csv"
    )

    val countryDF = spark.read.format("csv")
      .option("header", "true")
      .option("inferSchema", "true")
      .load("src/main/resources/countries.csv")

    import spark.implicits._

    val resDF = shopsDF.join(countryDF,$"CountryISO_3166_2" === $"alpha-2","inner").join(
      ordersDF, countryDF.col("alpha-2") === ordersDF.col("CountryISO_3166_2"), "inner"
    )

    resDF.show(10)

  }

}
