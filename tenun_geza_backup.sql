-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: 127.0.0.1    Database: tenun_geza
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `order`
--

DROP TABLE IF EXISTS `order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `order` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userId` int(11) NOT NULL,
  `totalPrice` int(11) NOT NULL,
  `dpAmount` int(11) DEFAULT 0,
  `status` varchar(191) NOT NULL DEFAULT 'PENDING',
  `paymentProofUrl` text DEFAULT NULL,
  `midtransOrderId` varchar(191) DEFAULT NULL,
  `snapToken` varchar(191) DEFAULT NULL,
  `snapUrl` varchar(191) DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `trackingStatus` text DEFAULT NULL,
  `courierName` varchar(191) DEFAULT NULL,
  `awbNumber` varchar(191) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Order_midtransOrderId_key` (`midtransOrderId`),
  KEY `Order_userId_fkey` (`userId`),
  CONSTRAINT `Order_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `user` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order`
--

LOCK TABLES `order` WRITE;
/*!40000 ALTER TABLE `order` DISABLE KEYS */;
INSERT INTO `order` VALUES (1,3,2000000,1000000,'DELIVERED','http://localhost:3000/uploads/1782362619784.png',NULL,NULL,NULL,NULL,NULL,'Pesanan telah diterima. Terima kasih telah berbelanja di Tenun Geza!','JnT','PDE1627812631','2026-06-25 04:40:22.016','2026-06-25 04:45:20.922'),(2,3,4500000,2250000,'DELIVERED','http://172.16.70.27:3000/uploads/1782448111318.jpg',NULL,NULL,NULL,NULL,NULL,'Pesanan telah diterima. Terima kasih telah berbelanja di Tenun Geza!','JnT','CDA15272818','2026-06-26 04:24:16.285','2026-06-26 04:30:37.139'),(4,3,4500000,2250000,'DELIVERED','http://localhost:3000/uploads/1782965742872.jpeg',NULL,NULL,NULL,NULL,NULL,'Pesanan telah diterima. Terima kasih telah berbelanja di Tenun Geza!','JNE','DFC512345','2026-07-02 04:09:57.501','2026-07-02 04:18:44.925'),(8,3,4500000,2250000,'PAID','http://172.16.71.88:3000/uploads/1782975613742.jpg',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-07-02 06:25:13.575','2026-07-03 06:24:47.209'),(9,3,4500000,2250000,'PENDING',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-07-03 06:31:28.791','2026-07-03 06:31:28.791'),(10,3,4500000,2250000,'PROCESSED','http://localhost:3000/uploads/1783316806416.jpeg',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-07-06 01:49:59.392','2026-07-07 04:36:16.699');
/*!40000 ALTER TABLE `order` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `orderitem`
--

DROP TABLE IF EXISTS `orderitem`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `orderitem` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orderId` int(11) NOT NULL,
  `productId` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `price` int(11) NOT NULL,
  `size` varchar(191) DEFAULT NULL,
  `notes` varchar(191) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `OrderItem_orderId_fkey` (`orderId`),
  KEY `OrderItem_productId_fkey` (`productId`),
  CONSTRAINT `OrderItem_orderId_fkey` FOREIGN KEY (`orderId`) REFERENCES `order` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `OrderItem_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `product` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orderitem`
--

LOCK TABLES `orderitem` WRITE;
/*!40000 ALTER TABLE `orderitem` DISABLE KEYS */;
INSERT INTO `orderitem` VALUES (2,2,2,1,4500000,'1 Meter',''),(4,4,2,1,4500000,'1 Meter',''),(8,8,2,1,4500000,'1 Meter',''),(9,9,2,1,4500000,'1 Meter',''),(10,10,3,1,4500000,'1 Meter','');
/*!40000 ALTER TABLE `orderitem` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `otp`
--

DROP TABLE IF EXISTS `otp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `otp` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(191) NOT NULL,
  `otp` varchar(191) NOT NULL,
  `expiresAt` datetime(3) NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `Otp_email_key` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otp`
--

LOCK TABLES `otp` WRITE;
/*!40000 ALTER TABLE `otp` DISABLE KEYS */;
/*!40000 ALTER TABLE `otp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product`
--

DROP TABLE IF EXISTS `product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(191) NOT NULL,
  `description` text NOT NULL,
  `price` int(11) NOT NULL,
  `imageUrl` varchar(191) NOT NULL,
  `stock` int(11) NOT NULL,
  `status` varchar(191) NOT NULL DEFAULT 'ACTIVE',
  `rating` double NOT NULL DEFAULT 0,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product`
--

LOCK TABLES `product` WRITE;
/*!40000 ALTER TABLE `product` DISABLE KEYS */;
INSERT INTO `product` VALUES (2,'Sepasang Baju Pengantin Motif Pucuk Sawit','sepasang set baju pengantin dengan design yang mewah',4500000,'http://localhost:3000/uploads/1782446204946.jpeg',10,'ACTIVE',4.5,'2026-06-26 03:56:44.997','2026-07-02 04:18:56.608'),(3,'Sepasang Baju Pengantin Dengan Motif Pucuk Rebung','motif yang sangat menyejukkan mata',4500000,'http://localhost:3000/uploads/1782446339749.jpeg',10,'ACTIVE',0,'2026-06-26 03:58:59.764','2026-06-26 03:58:59.764'),(4,'Sepasang Baju Pengantin Motif Pucuk Rebung','bahan yang sangat sejuk saat digunakan',4500000,'http://localhost:3000/uploads/1782446404896.jpeg',10,'ACTIVE',0,'2026-06-26 04:00:04.906','2026-06-26 04:00:04.906');
/*!40000 ALTER TABLE `product` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `review`
--

DROP TABLE IF EXISTS `review`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `review` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `productId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `userName` varchar(191) NOT NULL,
  `rating` int(11) NOT NULL DEFAULT 5,
  `comment` text NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  PRIMARY KEY (`id`),
  KEY `Review_productId_fkey` (`productId`),
  CONSTRAINT `Review_productId_fkey` FOREIGN KEY (`productId`) REFERENCES `product` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `review`
--

LOCK TABLES `review` WRITE;
/*!40000 ALTER TABLE `review` DISABLE KEYS */;
INSERT INTO `review` VALUES (4,2,3,'Customer',5,'pesanan sesuai dengan deskripsi dan bahan sangat bagus','2026-06-26 04:31:25.849'),(5,2,3,'Customer',4,'barang sesuai deskripsi','2026-07-02 04:18:56.596');
/*!40000 ALTER TABLE `review` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reviewimage`
--

DROP TABLE IF EXISTS `reviewimage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reviewimage` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `reviewId` int(11) NOT NULL,
  `imageUrl` text NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  PRIMARY KEY (`id`),
  KEY `ReviewImage_reviewId_fkey` (`reviewId`),
  CONSTRAINT `ReviewImage_reviewId_fkey` FOREIGN KEY (`reviewId`) REFERENCES `review` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reviewimage`
--

LOCK TABLES `reviewimage` WRITE;
/*!40000 ALTER TABLE `reviewimage` DISABLE KEYS */;
INSERT INTO `reviewimage` VALUES (3,4,'http://172.16.70.27:3000/uploads/1782448281518.jpg','2026-06-26 04:31:25.855');
/*!40000 ALTER TABLE `reviewimage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `storesettings`
--

DROP TABLE IF EXISTS `storesettings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `storesettings` (
  `id` int(11) NOT NULL DEFAULT 1,
  `bankName` varchar(191) NOT NULL DEFAULT 'BCA',
  `bankAccount` varchar(191) NOT NULL DEFAULT '1234567890',
  `accountName` varchar(191) NOT NULL DEFAULT 'TENUN GEZA OFFICIAL',
  `qrisImageUrl` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `storesettings`
--

LOCK TABLES `storesettings` WRITE;
/*!40000 ALTER TABLE `storesettings` DISABLE KEYS */;
INSERT INTO `storesettings` VALUES (1,'BCA','1234567890','TENUN GEZA OFFICIAL','http://localhost:3000/uploads/1782362301562.jpeg');
/*!40000 ALTER TABLE `storesettings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(191) NOT NULL,
  `password` varchar(191) NOT NULL,
  `name` varchar(191) NOT NULL,
  `phone` varchar(191) DEFAULT NULL,
  `role` varchar(191) NOT NULL DEFAULT 'USER',
  `status` varchar(191) NOT NULL DEFAULT 'ACTIVE',
  `birthDate` varchar(191) DEFAULT NULL,
  `isTwoFactorEnabled` tinyint(1) NOT NULL DEFAULT 0,
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `User_email_key` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,'admin@geza.com','$2b$10$7xiM5B8QWjkYauSTz8k2/O2UWE3fhi1EidqXlkmJsrZASKI1PiV1a','Admin Geza',NULL,'ADMIN','ACTIVE',NULL,0,'2026-06-25 04:34:43.073','2026-07-02 06:46:30.225'),(2,'tenungeza@gmail.com','$2b$10$D4X6/lTP2AeR32sPzKsLB.QqKTLCviG4xjp4NyChJdRLTq9KjzEVy','tenungeza','082286553714','PENJUAL','ACTIVE',NULL,0,'2026-06-25 04:36:22.448','2026-06-25 04:36:22.448'),(3,'andifanirfan@gmail.com','$2b$10$aES1o45KIsRddHlw.1AvhOC/EiHjyqzkz4zo26m6kx5S1gK1RH3LG','andifan','08286553714','USER','ACTIVE','',0,'2026-06-25 04:39:47.061','2026-07-02 04:50:59.657'),(4,'sutriulandari4@gmail.com','$2b$10$AcWfsbv12CwyRcrJaCfuEukJ4eutdZ3pNcPBUZp0PCayYGLmTdIES','sutri ulandari','082286553714','USER','ACTIVE',NULL,0,'2026-07-01 15:11:02.858','2026-07-01 15:11:02.858');
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `useraddress`
--

DROP TABLE IF EXISTS `useraddress`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `useraddress` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userId` int(11) NOT NULL,
  `name` varchar(191) NOT NULL,
  `phone` varchar(191) NOT NULL,
  `province` varchar(191) NOT NULL,
  `city` varchar(191) NOT NULL,
  `district` varchar(191) NOT NULL,
  `postalCode` varchar(191) NOT NULL,
  `streetAddress` text NOT NULL,
  `detailAddress` text DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `isMain` tinyint(1) NOT NULL DEFAULT 0,
  `label` varchar(191) NOT NULL DEFAULT 'RUMAH',
  `createdAt` datetime(3) NOT NULL DEFAULT current_timestamp(3),
  `updatedAt` datetime(3) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `UserAddress_userId_fkey` (`userId`),
  CONSTRAINT `UserAddress_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `user` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `useraddress`
--

LOCK TABLES `useraddress` WRITE;
/*!40000 ALTER TABLE `useraddress` DISABLE KEYS */;
/*!40000 ALTER TABLE `useraddress` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-07-10 10:39:55
