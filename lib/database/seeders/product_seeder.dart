// lib/database/seeders/product_seeder.dart

import 'package:sqflite/sqflite.dart';

class ProductSeeder {
  static Future<void> run(Database db) async {
    print('🌱 Seeding products...');

    final products = [
      // Material Bangunan
      {'id_product': 1, 'nama': 'PARALON PVC POWER 1/2 "', 'harga': 28000.0},
      {'id_product': 2, 'nama': 'PARALON PVC POWER 3/4"', 'harga': 34000.0},
      {'id_product': 3, 'nama': 'KNE 3/4"', 'harga': 2000.0},
      {'id_product': 4, 'nama': 'KNE 1/2"', 'harga': 1500.0},
      {'id_product': 5, 'nama': 'SDD 1/2"', 'harga': 2000.0},
      {'id_product': 6, 'nama': 'BALVALE 1/2"', 'harga': 18000.0},
      {'id_product': 7, 'nama': 'BALVALE 2"', 'harga': 86000.0},
      {'id_product': 8, 'nama': 'TE 3/4"', 'harga': 3000.0},
      {'id_product': 9, 'nama': 'SELTIP KECIL', 'harga': 5000.0},
      {'id_product': 10, 'nama': 'ISARPLAS KECIL', 'harga': 10000.0},
      
      // Pupuk Pertanian
      {'id_product': 11, 'nama': 'ZA TAWON. 50 KG', 'harga': 273000.0},
      {'id_product': 12, 'nama': 'NPK TAWON 50', 'harga': 668000.0},
      {'id_product': 13, 'nama': 'NPK PAK TANI 50', 'harga': 663000.0},
      {'id_product': 14, 'nama': 'FERTIPOS HITAM 50', 'harga': 168000.0},
      {'id_product': 15, 'nama': 'HX AS SUPER ( DGW SUPER ) 50', 'harga': 238000.0},
      {'id_product': 16, 'nama': 'ZA TAWON OREN. 50KG', 'harga': 198000.0},
      {'id_product': 17, 'nama': 'ZA PAK TANI GRANULL. 50 KG', 'harga': 245500.0},
      {'id_product': 18, 'nama': 'ZA DAUN CINA 50KG', 'harga': 198000.0},
      {'id_product': 19, 'nama': 'ZA DAUN TAIWAN 50KG', 'harga': 203000.0},
      {'id_product': 20, 'nama': 'SAPRODAP MAKRO 25KG', 'harga': 268000.0},
      {'id_product': 21, 'nama': 'UREA DAUN BUAH GRANDULL.10KG', 'harga': 75500.0},
      {'id_product': 22, 'nama': 'NPK GROWER 50', 'harga': 693000.0},
      {'id_product': 23, 'nama': 'PUPUK UREA PETRO KJ 5KG', 'harga': 43000.0},
      {'id_product': 24, 'nama': 'PONSKA PLUS KJ 25KG', 'harga': 220500.0},
      {'id_product': 25, 'nama': 'PUPUK UREA PETRO 50KG', 'harga': 333000.0},
      
      // Obat Pertanian
      {'id_product': 26, 'nama': 'Abacel 100', 'harga': 34000.0},
      {'id_product': 27, 'nama': 'Abacel 250', 'harga': 53000.0},
      {'id_product': 28, 'nama': 'Acrobat, 12.5', 'harga': 13000.0},
      {'id_product': 29, 'nama': 'ACROBAT.11', 'harga': 13000.0},
      {'id_product': 30, 'nama': 'Agrimec 250', 'harga': 102000.0},
      {'id_product': 31, 'nama': 'Agrogib, 30', 'harga': 32000.0},
      {'id_product': 32, 'nama': 'ANTONIC', 'harga': 60000.0},
      {'id_product': 33, 'nama': 'Antracol 250, 41 kecil', 'harga': 43000.0},
      {'id_product': 34, 'nama': 'Antracol 500, 75 besar', 'harga': 78000.0},
      {'id_product': 35, 'nama': 'Apsa. Pelekat', 'harga': 132000.0},
      {'id_product': 36, 'nama': 'Arrivo 250, 23 besar', 'harga': 25500.0},
      {'id_product': 37, 'nama': 'Arrivo, 12.5 cilik', 'harga': 14500.0},
      {'id_product': 38, 'nama': 'Avidor, 25', 'harga': 25000.0},
      {'id_product': 39, 'nama': 'Bio Nasa', 'harga': 72000.0},
      {'id_product': 40, 'nama': 'Bion M', 'harga': 187000.0},
      {'id_product': 41, 'nama': 'Boron', 'harga': 27000.0},
      {'id_product': 42, 'nama': 'Bulfidor, 85', 'harga': 87500.0},
      {'id_product': 43, 'nama': 'Chrot 100, 60', 'harga': 60000.0},
      {'id_product': 44, 'nama': 'Chrot', 'harga': 120000.0},
      {'id_product': 45, 'nama': 'CNG', 'harga': 24000.0},
      {'id_product': 46, 'nama': 'Cruiser', 'harga': 36000.0},
      {'id_product': 47, 'nama': 'Cuacron 250', 'harga': 72000.0},
      {'id_product': 48, 'nama': 'Curacron 100ml', 'harga': 35000.0},
      {'id_product': 49, 'nama': 'Daconil 500gr', 'harga': 100000.0},
      {'id_product': 50, 'nama': 'Demolish, 72.5', 'harga': 75000.0},
      {'id_product': 51, 'nama': 'Ditan, 35 500ml', 'harga': 38000.0},
      {'id_product': 52, 'nama': 'FURADAM', 'harga': 37000.0},
      {'id_product': 53, 'nama': 'GANDASIL B kecil', 'harga': 12000.0},
      {'id_product': 54, 'nama': 'Gandasil B, 42.5', 'harga': 45000.0},
      {'id_product': 55, 'nama': 'GANDASIL D kecil', 'harga': 11000.0},
      {'id_product': 56, 'nama': 'Gandasil D, 40', 'harga': 42000.0},
      {'id_product': 57, 'nama': 'Gaucho', 'harga': 36000.0},
      {'id_product': 58, 'nama': 'GISENTRO 500 ml', 'harga': 125000.0},
      {'id_product': 59, 'nama': 'Gramoxone, 68-70 1 l', 'harga': 63000.0},
      {'id_product': 60, 'nama': 'Gramoxone, kecil 500 ml', 'harga': 37000.0},
      {'id_product': 61, 'nama': 'Kayabas 250, 72 kecil', 'harga': 73000.0},
      {'id_product': 62, 'nama': 'Kayabas 500, 140, besar', 'harga': 133000.0},
      {'id_product': 63, 'nama': 'KNO merah, 58', 'harga': 60000.0},
      {'id_product': 64, 'nama': 'KNO pitih, 74', 'harga': 76000.0},
      {'id_product': 65, 'nama': 'LANET SP 25', 'harga': 80000.0},
      {'id_product': 66, 'nama': 'Mamigrow B, 37.5(ijo)', 'harga': 39500.0},
      {'id_product': 67, 'nama': 'Mamigrow D, 32.5(oren)', 'harga': 34500.0},
      {'id_product': 68, 'nama': 'Marsal bubuk, 8.5', 'harga': 11000.0},
      {'id_product': 69, 'nama': 'Marshal cair 100ml.', 'harga': 24000.0},
      {'id_product': 70, 'nama': 'Methindo', 'harga': 52000.0},
      {'id_product': 71, 'nama': 'MKP', 'harga': 53000.0},
      {'id_product': 72, 'nama': 'MOSPILAN BESAR', 'harga': 84000.0},
      {'id_product': 73, 'nama': 'MOSPILAN KECIL', 'harga': 28000.0},
      {'id_product': 74, 'nama': 'Nativo 65( gede)', 'harga': 67500.0},
      {'id_product': 75, 'nama': 'Nativo, 20 (cilik )', 'harga': 22000.0},
      {'id_product': 76, 'nama': 'Onyx', 'harga': 19000.0},
      {'id_product': 77, 'nama': 'Perekat Tembus', 'harga': 32000.0},
      {'id_product': 78, 'nama': 'Power zinc', 'harga': 27000.0},
      {'id_product': 79, 'nama': 'Prevaton 100, 65', 'harga': 67000.0},
      {'id_product': 80, 'nama': 'Regent red 50', 'harga': 26000.0},
      {'id_product': 81, 'nama': 'Ridomil gold', 'harga': 92000.0},
      {'id_product': 82, 'nama': 'Roundup, 80', 'harga': 80000.0},
      {'id_product': 83, 'nama': 'SantaQuat', 'harga': 57000.0},
      {'id_product': 84, 'nama': 'Saturn, 35', 'harga': 37500.0},
      {'id_product': 85, 'nama': 'Score 250, 170 gede', 'harga': 172000.0},
      {'id_product': 86, 'nama': 'Score 80, 59,cilik', 'harga': 62000.0},
      {'id_product': 87, 'nama': 'Spontan 500 ml', 'harga': 43000.0},
      {'id_product': 88, 'nama': 'Spuyer Paten', 'harga': 22000.0},
      {'id_product': 89, 'nama': 'Spuyer Tanika', 'harga': 37000.0},
      {'id_product': 90, 'nama': 'TOP ZONE.55', 'harga': 57000.0},
      {'id_product': 91, 'nama': 'Topshot, 92.5', 'harga': 94000.0},
      {'id_product': 92, 'nama': 'Topshot', 'harga': 165000.0},
      {'id_product': 93, 'nama': 'TORAM', 'harga': 29000.0},
      {'id_product': 94, 'nama': 'Ultradap', 'harga': 44000.0},
      {'id_product': 95, 'nama': 'NOMINE', 'harga': 180000.0},
      {'id_product': 96, 'nama': 'EMASIL', 'harga': 90000.0},
      {'id_product': 97, 'nama': 'EMACEL', 'harga': 71000.0},
      {'id_product': 98, 'nama': 'PLENUM', 'harga': 128000.0},
      {'id_product': 99, 'nama': 'SUMO', 'harga': 55000.0},
      {'id_product': 100, 'nama': 'RINJANI', 'harga': 55000.0},
      {'id_product': 101, 'nama': 'GROWNIL', 'harga': 140000.0},
      {'id_product': 102, 'nama': 'NPK TAWON', 'harga': 18000.0},
      {'id_product': 103, 'nama': 'PEREKAT BISMORE', 'harga': 65000.0},
      {'id_product': 104, 'nama': 'GLOWINHG 1 Lt', 'harga': 25000.0},
      {'id_product': 105, 'nama': 'LINDOMIL', 'harga': 28000.0},
      {'id_product': 106, 'nama': 'OBAT TIKUS SACET', 'harga': 4000.0},
      {'id_product': 107, 'nama': 'OBAT TIKUS TETES', 'harga': 16000.0},
      {'id_product': 108, 'nama': 'AMBITION 500 ml', 'harga': 86000.0},
      {'id_product': 109, 'nama': 'Amistartop', 'harga': 255000.0},
      {'id_product': 110, 'nama': 'BOADPLUSS,HERBI PARI', 'harga': 15000.0},
      {'id_product': 111, 'nama': 'Buldox', 'harga': 65000.0},
      {'id_product': 112, 'nama': 'Centaxone', 'harga': 35000.0},
      {'id_product': 113, 'nama': 'DANGKE 100', 'harga': 26000.0},
      {'id_product': 114, 'nama': 'DANGKE 250', 'harga': 57000.0},
      {'id_product': 115, 'nama': 'DECIS', 'harga': 75000.0},
      {'id_product': 116, 'nama': 'DESTANE', 'harga': 55000.0},
      {'id_product': 117, 'nama': 'DHITAN 500 ml', 'harga': 75000.0},
      {'id_product': 118, 'nama': 'DHITAN 200 gram', 'harga': 38000.0},
      {'id_product': 119, 'nama': 'EM 4', 'harga': 23000.0},
      {'id_product': 120, 'nama': 'EMACEL 250 ml', 'harga': 75000.0},
      {'id_product': 121, 'nama': 'EMACEL 100 ml', 'harga': 35000.0},
      {'id_product': 122, 'nama': 'GANDEWA', 'harga': 130000.0},
      {'id_product': 123, 'nama': 'GAWAR PARALON', 'harga': 33000.0},
      {'id_product': 124, 'nama': 'GAWAR WESI', 'harga': 27000.0},
      {'id_product': 125, 'nama': 'GEMPUR', 'harga': 55000.0},
      {'id_product': 126, 'nama': 'GISENTRO 1 lt', 'harga': 225000.0},
      {'id_product': 127, 'nama': 'GLOWING 500 ml', 'harga': 15000.0},
      {'id_product': 128, 'nama': 'GLUFO', 'harga': 77000.0},
      {'id_product': 129, 'nama': 'GOAL Herbisida', 'harga': 60000.0},
      {'id_product': 130, 'nama': 'HERBISIDA MACERIO jagung', 'harga': 25000.0},
      {'id_product': 131, 'nama': 'RUMPAS 100ml', 'harga': 45000.0},
      {'id_product': 132, 'nama': 'RUMPAS 250ml', 'harga': 103000.0},
      {'id_product': 133, 'nama': 'SATURN 35', 'harga': 35000.0},
      {'id_product': 134, 'nama': 'Sprinter,HERBI', 'harga': 42000.0},
      {'id_product': 135, 'nama': 'Tabass', 'harga': 107000.0},
      {'id_product': 136, 'nama': 'TOP ZONE 55', 'harga': 57000.0},
      {'id_product': 137, 'nama': 'INDOKUAT H', 'harga': 35000.0},
      {'id_product': 138, 'nama': 'INSURMEX', 'harga': 36000.0},
      {'id_product': 139, 'nama': 'KNO3 DGW KRISTAL', 'harga': 65000.0},
      {'id_product': 140, 'nama': 'KNO3 DGW PRILL', 'harga': 73000.0},
      {'id_product': 141, 'nama': 'MANOHARA', 'harga': 25000.0},
      {'id_product': 142, 'nama': 'MARXONE,H', 'harga': 55000.0},
      {'id_product': 143, 'nama': 'NORDOX 100', 'harga': 25000.0},
      {'id_product': 144, 'nama': 'Novleck 250 ml', 'harga': 203000.0},
      {'id_product': 145, 'nama': 'NPK BOSST TAWON 1KG', 'harga': 20000.0},
      {'id_product': 146, 'nama': 'NPK CAIR', 'harga': 25000.0},
      {'id_product': 147, 'nama': 'NUGROW 1 liter', 'harga': 32000.0},
      {'id_product': 148, 'nama': 'POLYSSTYK 1 L', 'harga': 20000.0},
      {'id_product': 149, 'nama': 'PROMOQUAT 20 L', 'harga': 450000.0},
      {'id_product': 150, 'nama': 'PROMOQUAT', 'harga': 45000.0},
      {'id_product': 151, 'nama': 'PROWL 500 ML', 'harga': 112000.0},
      {'id_product': 152, 'nama': 'Rizotyn 250', 'harga': 61000.0},
      {'id_product': 153, 'nama': 'Rizotyn 100', 'harga': 33000.0},
      {'id_product': 154, 'nama': 'RUMPUT JEPANG', 'harga': 400000.0},
      {'id_product': 155, 'nama': 'SAPORO 100ML', 'harga': 60000.0},
      {'id_product': 156, 'nama': 'SAPORO 250000', 'harga': 125000.0},
      {'id_product': 157, 'nama': 'ULTRON 8 GRAM', 'harga': 10000.0},
      {'id_product': 158, 'nama': 'ULTRON 20 GRAM', 'harga': 18000.0},
      {'id_product': 159, 'nama': 'WATER METER', 'harga': 0.0},
      {'id_product': 160, 'nama': 'ISARPLAS ONDA', 'harga': 12000.0},
      {'id_product': 161, 'nama': 'SOCK 1/2"', 'harga': 1500.0},
      {'id_product': 162, 'nama': 'Kran 1/2"', 'harga': 15000.0},
      {'id_product': 163, 'nama': 'ISARPLAS KALENG', 'harga': 60000.0},
      {'id_product': 164, 'nama': 'STOP KRAN 1/2"', 'harga': 20000.0},
      {'id_product': 165, 'nama': 'SELTIF BESAR ONDA', 'harga': 12000.0},
      {'id_product': 166, 'nama': 'NPK TAWON 1KG', 'harga': 17000.0},
      {'id_product': 167, 'nama': 'NPK BOOST TAWON 1KG', 'harga': 20000.0},
      {'id_product': 168, 'nama': 'KCL MAHKOTA 50 KG', 'harga': 360000.0},
      {'id_product': 169, 'nama': 'KNO3 DGW PRILL 2KG', 'harga': 75000.0},
      {'id_product': 170, 'nama': 'KNO 3 DGW KRISTAL 2KG', 'harga': 65000.0},
      {'id_product': 171, 'nama': 'ZA KANCIL IJO 50KG', 'harga': 220000.0},
      {'id_product': 172, 'nama': 'POSPAT AKASIA 50KG', 'harga': 150000.0},
      {'id_product': 173, 'nama': 'OREA KANCIL 40KG', 'harga': 215000.0},
      {'id_product': 174, 'nama': 'NPK PAK TANI 20KG', 'harga': 290000.0},
      {'id_product': 175, 'nama': 'UREA TAWON 40KG', 'harga': 222000.0},
      
      // Benih
      {'id_product': 176, 'nama': 'BISI 2', 'harga': 75000.0},
      {'id_product': 177, 'nama': 'PERTIWI 3', 'harga': 70000.0},
      {'id_product': 178, 'nama': 'PERTIWI 5', 'harga': 90000.0},
      {'id_product': 179, 'nama': 'JAGO', 'harga': 114000.0},
      {'id_product': 180, 'nama': 'MONTHOK', 'harga': 105000.0},
      {'id_product': 181, 'nama': 'NAGA', 'harga': 98000.0},
      {'id_product': 182, 'nama': 'MACHO', 'harga': 90000.0},
      {'id_product': 183, 'nama': 'PERKASA', 'harga': 110000.0},
      {'id_product': 184, 'nama': 'BISI 18', 'harga': 85000.0},
    ];

    try {
      for (var product in products) {
        // Data percobaan untuk mempermudah testing
        final harga = product['harga'] as double;
        product['harga_beli'] = harga * 0.8;
        product['stock'] = 25; // Stok default 25

        await db.insert(
          'products',
          product,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      print('✅ Products seeded successfully (${products.length} items)');
    } catch (e) {
      print('❌ Error seeding products: $e');
      rethrow;
    }
  }

  // Method untuk cek apakah produk sudah ada
  static Future<bool> hasData(Database db) async {
    final result = await db.query('products', limit: 1);
    return result.isNotEmpty;
  }

  // Method untuk seed hanya jika belum ada data
  static Future<void> seedIfEmpty(Database db) async {
    final hasProducts = await hasData(db);
    if (!hasProducts) {
      await run(db);
    } else {
      print('ℹ️  Products already seeded, skipping...');
    }
  }
}
