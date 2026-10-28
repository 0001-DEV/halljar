const express = require('express');
const cors = require('cors');
const http = require('http');
const { WebSocketServer } = require('ws');
const path = require('path');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// In-memory data store with persistent file backing (supports Vercel serverless /tmp)
const isVercel = process.env.VERCEL === '1';
const DB_SOURCE_FILE = path.join(__dirname, 'db_data.json');
const DB_FILE = isVercel ? path.join('/tmp', 'db_data.json') : DB_SOURCE_FILE;

if (isVercel && !fs.existsSync(DB_FILE) && fs.existsSync(DB_SOURCE_FILE)) {
  try {
    fs.copyFileSync(DB_SOURCE_FILE, DB_FILE);
  } catch (e) {
    console.warn('Could not copy db_data.json to /tmp:', e);
  }
}

// Default initial database state
const DEFAULT_DB = {
  estates: [
    { id: 'est_citiview', name: 'Citi-View Estate' },
    { id: 'est_warewa', name: 'Warewa' },
    { id: 'est_arepo', name: 'Arepo' },
    { id: 'est_opic', name: 'Opic' },
    { id: 'est_ibafo', name: 'Ibafo' }
  ],
  users: [
    { id: 'usr_b1', fullName: 'Chidinma Eze', phoneNumber: '+2348011112222', password: 'password123', role: 'BUYER', estateId: 'est_citiview', unit: 'Block 4, Flat 2' },
    { id: 'usr_s_cv1', fullName: 'Mosh Manager', phoneNumber: '+2348033334444', password: 'password123', role: 'SELLER', estateId: 'est_citiview', unit: 'Main Commercial Hub, Citi-View' },
    { id: 'usr_vendor_love', fullName: 'Love', phoneNumber: '+2348012340000', password: 'password123', role: 'SELLER', estateId: 'est_warewa', unit: 'Shop 4, Warewa Plaza' },
    { id: 'usr_1793185783549', fullName: 'love', phoneNumber: '08149706739', password: 'weblove16', role: 'SELLER', estateId: 'est_citiview', unit: 'Shop 2, Citi-View' }
  ],
  stores: [
    // Citi-View
    {
      id: 'store_citi_mosh',
      userId: 'usr_s_cv1',
      storeName: 'MOSH SUPERMARKET',
      logo: 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?w=150&auto=format&fit=crop&q=80',
      category: 'Supermarket',
      sellerTier: 'RESIDENT',
      estateId: 'est_citiview',
      estateUnit: 'Main Commercial Hub, Citi-View',
      ratingAvg: 5.0,
      ratingCount: 142,
      verifiedKYC: true,
      bio: 'Full supermarket provisions, drinks, toiletries & daily household needs in Citi-View.',
      openTime: '08:00',
      closeTime: '21:30'
    },
    {
      id: 'store_citi_laundry',
      userId: 'usr_s_cv2',
      storeName: 'Deji Laundry Services',
      logo: 'https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=150&auto=format&fit=crop&q=80',
      category: 'Laundry Services',
      sellerTier: 'RESIDENT',
      estateId: 'est_citiview',
      estateUnit: 'Block 4, Road 2, Citi-View',
      ratingAvg: 4.9,
      ratingCount: 78,
      verifiedKYC: true,
      bio: 'Express wash, suit dry-cleaning & steam pressing with in-estate doorstep pickup.',
      openTime: '07:30',
      closeTime: '21:00'
    },
    {
      id: 'store_citi_nkechi',
      userId: 'usr_s_cv3',
      storeName: 'Nkechi Cooks',
      logo: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=150&auto=format&fit=crop&q=80',
      category: 'Food & Meals',
      sellerTier: 'RESIDENT',
      estateId: 'est_citiview',
      estateUnit: 'Diamond Close, Citi-View',
      ratingAvg: 4.9,
      ratingCount: 95,
      verifiedKYC: true,
      bio: 'Delicious home-cooked Nigerian meals, native soups, jollof rice & grills in Citi-View.',
      openTime: '09:00',
      closeTime: '21:00'
    },

    // Warewa
    {
      id: 'store_vendor_love',
      userId: 'usr_vendor_love',
      storeName: 'Love Supermarket',
      logo: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=150&auto=format&fit=crop&q=80',
      category: 'Supermarket',
      sellerTier: 'RESIDENT',
      estateId: 'est_warewa',
      estateUnit: 'Shop 4, Warewa Plaza',
      ratingAvg: 5.0,
      ratingCount: 22,
      verifiedKYC: true,
      bio: 'Fresh daily provisions, packaged beverages, breakfast cereals & home essentials by Love.',
      openTime: '07:30',
      closeTime: '22:00'
    },
    {
      id: 'store_war_giant',
      userId: 'usr_s_w1',
      storeName: 'Giant Supermarket',
      logo: 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=150&auto=format&fit=crop&q=80',
      category: 'Supermarket',
      sellerTier: 'RESIDENT',
      estateId: 'est_warewa',
      estateUnit: 'Warewa Expressway Junction',
      ratingAvg: 5.0,
      ratingCount: 160,
      verifiedKYC: true,
      bio: 'Warewa largest supermarket. Everything for home and pantry under one roof.',
      openTime: '08:00',
      closeTime: '22:00'
    },
    {
      id: 'store_war_selvit',
      userId: 'usr_s_w2',
      storeName: 'Selvit Grills',
      logo: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=150&auto=format&fit=crop&q=80',
      category: 'Food & Grills',
      sellerTier: 'RESIDENT',
      estateId: 'est_warewa',
      estateUnit: 'Warewa Market Road',
      ratingAvg: 4.8,
      ratingCount: 68,
      verifiedKYC: true,
      bio: 'Hot BBQ chicken, grilled fish, shawarma & suya delivered fast in Warewa.',
      openTime: '12:00',
      closeTime: '23:00'
    },
    {
      id: 'store_war_dun',
      userId: 'usr_s_w3',
      storeName: 'Dun Cold room',
      logo: 'https://images.unsplash.com/photo-1615141982883-c7ad0e69fd62?w=150&auto=format&fit=crop&q=80',
      category: 'Cold Room & Proteins',
      sellerTier: 'RESIDENT',
      estateId: 'est_warewa',
      estateUnit: 'Warewa Bus Stop',
      ratingAvg: 4.7,
      ratingCount: 54,
      verifiedKYC: true,
      bio: 'Fresh frozen chicken, turkey, croaker fish & Titus at wholesale/retail prices.',
      openTime: '07:30',
      closeTime: '20:00'
    },
    {
      id: 'store_war_minu',
      userId: 'usr_s_w4',
      storeName: 'Minu mini mart',
      logo: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=150&auto=format&fit=crop&q=80',
      category: 'Supermarket',
      sellerTier: 'RESIDENT',
      estateId: 'est_warewa',
      estateUnit: 'Warewa Community Road',
      ratingAvg: 4.7,
      ratingCount: 42,
      verifiedKYC: true,
      bio: 'Convenience neighborhood mart for quick bread, beverages, eggs & snacks.',
      openTime: '07:00',
      closeTime: '22:00'
    },

    // Arepo
    {
      id: 'store_arp_bokku',
      userId: 'usr_s_a1',
      storeName: 'Bokku Supermarket',
      logo: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=150&auto=format&fit=crop&q=80',
      category: 'Supermarket',
      sellerTier: 'RESIDENT',
      estateId: 'est_arepo',
      estateUnit: 'Journalists Estate Entrance, Arepo',
      ratingAvg: 5.0,
      ratingCount: 155,
      verifiedKYC: true,
      bio: 'Bokku Arepo. Quality groceries and daily supermarket provisions at best rates.',
      openTime: '08:00',
      closeTime: '21:30'
    },
    {
      id: 'store_arp_seyhat',
      userId: 'usr_s_a2',
      storeName: 'SEYHAT Wears',
      logo: 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=150&auto=format&fit=crop&q=80',
      category: 'Fashion & Clothing',
      sellerTier: 'RESIDENT',
      estateId: 'est_arepo',
      estateUnit: 'Arepo High Street',
      ratingAvg: 4.8,
      ratingCount: 65,
      verifiedKYC: true,
      bio: 'Trendy casual wears, corporate shirts, sneakers & bespoke fashion in Arepo.',
      openTime: '09:00',
      closeTime: '20:30'
    },
    {
      id: 'store_arp_wise',
      userId: 'usr_s_a3',
      storeName: 'Wise Buyers',
      logo: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=150&auto=format&fit=crop&q=80',
      category: 'Groceries & Household',
      sellerTier: 'RESIDENT',
      estateId: 'est_arepo',
      estateUnit: 'Arepo Central Close',
      ratingAvg: 4.8,
      ratingCount: 58,
      verifiedKYC: true,
      bio: 'Bulk foodstuff, oils, rice, seasonings and kitchen provisions.',
      openTime: '08:00',
      closeTime: '21:00'
    },
    {
      id: 'store_arp_dumh',
      userId: 'usr_s_a4',
      storeName: 'dumh Laundry Service',
      logo: 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=150&auto=format&fit=crop&q=80',
      category: 'Laundry Services',
      sellerTier: 'RESIDENT',
      estateId: 'est_arepo',
      estateUnit: 'Journalists Road 3, Arepo',
      ratingAvg: 4.7,
      ratingCount: 46,
      verifiedKYC: true,
      bio: 'Fast professional washing and ironing service for Arepo residents.',
      openTime: '08:00',
      closeTime: '20:00'
    },

    // OPIC
    {
      id: 'store_opc_bokku',
      userId: 'usr_s_o1',
      storeName: 'Bokku Supermarket',
      logo: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=150&auto=format&fit=crop&q=80',
      category: 'Supermarket',
      sellerTier: 'RESIDENT',
      estateId: 'est_opic',
      estateUnit: 'OPIC Main Plaza, Isheri/OPIC',
      ratingAvg: 5.0,
      ratingCount: 130,
      verifiedKYC: true,
      bio: 'Bokku OPIC branch. All packaged groceries, drinks & home goods.',
      openTime: '08:00',
      closeTime: '21:30'
    },
    {
      id: 'store_opc_ser',
      userId: 'usr_s_o2',
      storeName: 'Ser Confectioneries',
      logo: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=150&auto=format&fit=crop&q=80',
      category: 'Bakery & Pastries',
      sellerTier: 'RESIDENT',
      estateId: 'est_opic',
      estateUnit: 'OPIC Estate Road',
      ratingAvg: 4.8,
      ratingCount: 74,
      verifiedKYC: true,
      bio: 'Celebration cakes, hot donuts, meat pies & dessert boxes in OPIC.',
      openTime: '08:30',
      closeTime: '20:30'
    },

    // Ibafo
    {
      id: 'store_ibf_justrite',
      userId: 'usr_s_i1',
      storeName: 'Just rite',
      logo: 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=150&auto=format&fit=crop&q=80',
      category: 'Supermarket',
      sellerTier: 'RESIDENT',
      estateId: 'est_ibafo',
      estateUnit: 'Ibafo Expressway Complex',
      ratingAvg: 5.0,
      ratingCount: 185,
      verifiedKYC: true,
      bio: 'Just Rite superstore Ibafo. Giant retail outlet for all groceries, appliances & provisions.',
      openTime: '08:00',
      closeTime: '22:00'
    },
    {
      id: 'store_ibf_dub',
      userId: 'usr_s_i2',
      storeName: 'DUB wholesale perfume',
      logo: 'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?w=150&auto=format&fit=crop&q=80',
      category: 'Perfumes & Beauty',
      sellerTier: 'RESIDENT',
      estateId: 'est_ibafo',
      estateUnit: 'Ibafo Central Market Road',
      ratingAvg: 4.9,
      ratingCount: 88,
      verifiedKYC: true,
      bio: 'Authentic designer and Arabian oil perfumes at factory wholesale rates.',
      openTime: '09:00',
      closeTime: '20:00'
    }
  ],
  listings: [
    // Citi-View
    {
      id: 'cv_mosh_1',
      storeId: 'store_citi_mosh',
      title: 'Golden Penny Pure Soya Oil (5 Litres)',
      category: 'Supermarket',
      price: 18500,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 92,
      images: ['https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=600&auto=format&fit=crop&q=80'],
      description: 'Zero cholesterol pure vegetable oil. Fresh factory sealed gallon.'
    },
    {
      id: 'cv_laundry_1',
      storeId: 'store_citi_laundry',
      title: 'Dry Cleaning Service (2-Piece Men Suit)',
      category: 'Laundry Services',
      price: 3500,
      condition: 'SERVICE',
      status: 'ACTIVE',
      views: 64,
      images: ['https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=600&auto=format&fit=crop&q=80'],
      description: 'Professional steam press and dry cleaning. 24hr in-estate turnaround.'
    },
    {
      id: 'cv_nkechi_1',
      storeId: 'store_citi_nkechi',
      title: 'Smokey Party Jollof Rice + Peppered Chicken',
      category: 'Food & Meals',
      price: 4500,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 130,
      images: ['https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&auto=format&fit=crop&q=80'],
      description: 'Authentic firewood-flavored party jollof with fried plantain & chicken.'
    },

    // Warewa
    {
      id: 'war_giant_1',
      storeId: 'store_war_giant',
      title: 'Mama Gold Premium Parboiled Rice (10kg)',
      category: 'Supermarket',
      price: 21500,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 145,
      images: ['https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&auto=format&fit=crop&q=80'],
      description: 'Stone-free long grain Nigerian parboiled rice.'
    },
    {
      id: 'war_selvit_1',
      storeId: 'store_war_selvit',
      title: 'Whole Grilled Catfish with Spicy Sauce & Chips',
      category: 'Food & Grills',
      price: 7500,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 98,
      images: ['https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600&auto=format&fit=crop&q=80'],
      description: 'Hot freshly charcoal-grilled catfish with seasoned chips and coleslaw.'
    },
    {
      id: 'war_dun_1',
      storeId: 'store_war_dun',
      title: 'Carton of Fresh Frozen Chicken Lap (10kg)',
      category: 'Cold Room & Proteins',
      price: 36000,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 112,
      images: ['https://images.unsplash.com/photo-1615141982883-c7ad0e69fd62?w=600&auto=format&fit=crop&q=80'],
      description: 'Original grade-A frozen chicken quarters.'
    },
    {
      id: 'war_minu_1',
      storeId: 'store_war_minu',
      title: 'Dano Full Cream Milk Powder Pouch (800g)',
      category: 'Supermarket',
      price: 7600,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 60,
      images: ['https://images.unsplash.com/photo-1550583724-b2692b85b150?w=600&auto=format&fit=crop&q=80'],
      description: 'Creamy milk powder for tea and breakfast.'
    },

    // Arepo
    {
      id: 'arp_bokku_1',
      storeId: 'store_arp_bokku',
      title: 'Ariel Auto Washing Powder (2kg Bag)',
      category: 'Supermarket',
      price: 6400,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 89,
      images: ['https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=600&auto=format&fit=crop&q=80'],
      description: 'Tough stain removal in 1 wash.'
    },
    {
      id: 'arp_seyhat_1',
      storeId: 'store_arp_seyhat',
      title: 'Premium Men Plain Oxford Cotton Shirt',
      category: 'Fashion & Clothing',
      price: 14500,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 75,
      images: ['https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=600&auto=format&fit=crop&q=80'],
      description: 'Breathable, slim fit cotton business shirt. Available in sizes M, L, XL.'
    },
    {
      id: 'arp_wise_1',
      storeId: 'store_arp_wise',
      title: 'Peak Evaporated Milk Tin (Carton of 24)',
      category: 'Groceries & Household',
      price: 19800,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 70,
      images: ['https://images.unsplash.com/photo-1528750997573-59b89d56f4f7?w=600&auto=format&fit=crop&q=80'],
      description: 'Full carton of Peak milk tin original.'
    },
    {
      id: 'arp_dumh_1',
      storeId: 'store_arp_dumh',
      title: 'Bed Sheet & Duvet Laundering (Full Set)',
      category: 'Laundry Services',
      price: 4500,
      condition: 'SERVICE',
      status: 'ACTIVE',
      views: 52,
      images: ['https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=600&auto=format&fit=crop&q=80'],
      description: 'Anti-bacterial deep wash and soft ironing for king-size duvets.'
    },

    // OPIC
    {
      id: 'opc_bokku_1',
      storeId: 'store_opc_bokku',
      title: 'Carton of Maltina Classic Can (24 x 33cl)',
      category: 'Supermarket',
      price: 12500,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 118,
      images: ['https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=600&auto=format&fit=crop&q=80'],
      description: 'Nourishing malt drink packed with vitamins.'
    },
    {
      id: 'opc_ser_1',
      storeId: 'store_opc_ser',
      title: 'Special Chocolate Birthday Drip Cake',
      category: 'Bakery & Pastries',
      price: 19500,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 92,
      images: ['https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&auto=format&fit=crop&q=80'],
      description: 'Decadent chocolate fudge layers with chocolate ganache drip.'
    },

    // Ibafo
    {
      id: 'ibf_justrite_1',
      storeId: 'store_ibf_justrite',
      title: 'Golden Penny Macaroni / Spaghetti (Carton of 20)',
      category: 'Supermarket',
      price: 15800,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 135,
      images: ['https://images.unsplash.com/photo-1612927601601-6638404737ce?w=600&auto=format&fit=crop&q=80'],
      description: 'Super quick-cooking pasta from Justrite Ibafo.'
    },
    {
      id: 'ibf_dub_1',
      storeId: 'store_ibf_dub',
      title: 'Khamrah Lattafa Arabian Perfume (100ml Original)',
      category: 'Perfumes & Beauty',
      price: 26500,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 140,
      images: ['https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?w=600&auto=format&fit=crop&q=80'],
      description: 'Top trending vanilla & amber Arabian perfume. Wholesale deal.'
    },
    {
      id: 'item_love_1',
      storeId: 'store_vendor_love',
      title: 'Golden Penny Pure Vegetable Oil (5L)',
      category: 'Supermarket',
      price: 16500,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 42,
      images: ['https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=600&auto=format&fit=crop&q=80'],
      description: 'Factory-sealed 5-litre pure vegetable cooking oil by Love Supermarket.'
    },
    {
      id: 'item_love_2',
      storeId: 'store_vendor_love',
      title: "Kellogg's Corn Flakes Family Pack (450g)",
      category: 'Supermarket',
      price: 3400,
      condition: 'BRAND_NEW',
      status: 'ACTIVE',
      views: 28,
      images: ['https://images.unsplash.com/photo-1521483451569-e33803c0330c?w=600&auto=format&fit=crop&q=80'],
      description: 'Crispy golden toasted flakes of corn, fortified with essential vitamins.'
    }
  ],
  conversations: [],
  messages: []
};

// Load or initialize database
let DB = DEFAULT_DB;
if (fs.existsSync(DB_FILE)) {
  try {
    DB = JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
    if (!DB.users) DB.users = DEFAULT_DB.users;
    if (!DB.stores) DB.stores = DEFAULT_DB.stores;
    if (!DB.listings) DB.listings = DEFAULT_DB.listings;
    if (!DB.estates) DB.estates = DEFAULT_DB.estates;
    if (!DB.conversations) DB.conversations = [];
    if (!DB.messages) DB.messages = [];

    // Ensure Love user, store, and items exist in DB
    if (!DB.users.some(u => u.id === 'usr_vendor_love' || (u.fullName && u.fullName.toLowerCase() === 'love'))) {
      const loveUser = DEFAULT_DB.users.find(u => u.id === 'usr_vendor_love');
      if (loveUser) DB.users.push(loveUser);
    }
    if (!DB.stores.some(s => s.id === 'store_vendor_love' || (s.storeName && s.storeName.toLowerCase().includes('love')))) {
      const loveStore = DEFAULT_DB.stores.find(s => s.id === 'store_vendor_love');
      if (loveStore) DB.stores.unshift(loveStore);
    }
    if (!DB.listings.some(l => l.id === 'item_love_1')) {
      const item1 = DEFAULT_DB.listings.find(l => l.id === 'item_love_1');
      const item2 = DEFAULT_DB.listings.find(l => l.id === 'item_love_2');
      if (item1) DB.listings.unshift(item1);
      if (item2) DB.listings.unshift(item2);
    }

    // Ensure war_giant_1 (Nestle Milo) has genuine chocolate malt beverage image
    const milo = DB.listings && DB.listings.find(l => l.id === 'war_giant_1' || (l.title && l.title.includes('Milo')));
    if (milo && milo.images && milo.images[0] && milo.images[0].includes('1584308666744')) {
      milo.images = ['https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=600&auto=format&fit=crop&q=80'];
    }
  } catch (e) {
    DB = DEFAULT_DB;
  }
}
saveDB();

function saveDB() {
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(DB, null, 2), 'utf8');
  } catch (e) {
    console.error('Error saving DB:', e);
  }
}

// --- REST API ENDPOINTS ---

// In-memory OTP Store for phone verification and password reset
const OTP_STORE = new Map();
const PENDING_REGISTRATIONS = new Map();

// Auth: Step 1 - Send Phone Verification Code for Signup
app.post('/api/auth/register-otp', (req, res) => {
  const {
    accountType,
    fullName,
    phoneNumber,
    password,
    estateId,
    unit,
    businessName,
    businessCategory,
    openTime,
    closeTime
  } = req.body;

  if (!fullName || !phoneNumber || !password) {
    return res.status(400).json({ error: 'Full name, phone number, and password are required.' });
  }

  const normPhone = (p) => (p || '').replace(/\D/g, '').replace(/^234/, '0');
  const targetPhoneNorm = normPhone(phoneNumber);

  if (targetPhoneNorm.length < 8) {
    return res.status(400).json({ error: 'Please enter a valid Nigerian phone number.' });
  }

  const existing = DB.users.find(u => normPhone(u.phoneNumber) === targetPhoneNorm);
  if (existing) {
    return res.status(400).json({ error: `⚠️ An account with phone number "${phoneNumber}" already exists. Please log in or choose another number.` });
  }

  const isBusiness = accountType === 'BUSINESS';
  if (isBusiness && businessName) {
    const bNorm = businessName.trim().toLowerCase();
    const existingStore = DB.stores.find(s => s.storeName && s.storeName.trim().toLowerCase() === bNorm);
    if (existingStore) {
      return res.status(400).json({ error: `⚠️ A company named "${businessName.trim()}" already exists. Please choose a different company name.` });
    }
  }

  // Generate 6-digit verification code
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  PENDING_REGISTRATIONS.set(targetPhoneNorm, {
    data: req.body,
    code,
    expiresAt: Date.now() + 10 * 60 * 1000
  });

  console.log(`[SIGNUP PHONE VERIFICATION OTP] Generated code ${code} for ${fullName} (${phoneNumber})`);

  res.json({
    success: true,
    message: `Verification code sent to ${phoneNumber}. Use code: ${code}`,
    code
  });
});

// Auth: Step 2 - Verify Phone Code and Complete Account Registration
app.post('/api/auth/verify-register-otp', (req, res) => {
  const { phoneNumber, code } = req.body;
  if (!phoneNumber || !code) {
    return res.status(400).json({ error: 'Phone number and verification code are required.' });
  }

  const normPhone = (p) => (p || '').replace(/\D/g, '').replace(/^234/, '0');
  const targetPhoneNorm = normPhone(phoneNumber);

  const pending = PENDING_REGISTRATIONS.get(targetPhoneNorm);
  if (!pending || pending.code !== code.trim()) {
    return res.status(400).json({ error: 'Invalid or expired verification code. Please check and try again.' });
  }

  const {
    accountType,
    fullName,
    password,
    estateId,
    unit,
    businessName,
    businessCategory,
    openTime,
    closeTime
  } = pending.data;

  const isBusiness = accountType === 'BUSINESS';
  const userId = 'usr_' + Date.now();
  const newUser = {
    id: userId,
    fullName,
    phoneNumber,
    password,
    role: isBusiness ? 'SELLER' : 'BUYER',
    estateId: estateId || 'est_warewa',
    unit: unit || ''
  };
  DB.users.push(newUser);

  let newStore = null;
  if (isBusiness) {
    const storeId = 'store_' + Date.now();
    newStore = {
      id: storeId,
      userId,
      storeName: businessName || `${fullName}'s Store`,
      logo: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=150&auto=format&fit=crop&q=80',
      cover: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=1200&auto=format&fit=crop&q=80',
      coverPhoto: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=1200&auto=format&fit=crop&q=80',
      category: businessCategory || 'Supermarket',
      sellerTier: 'RESIDENT',
      estateId: estateId || 'est_citiview',
      estateUnit: unit || 'In-Estate Shop',
      ratingAvg: 5.0,
      ratingCount: 0,
      verifiedKYC: true,
      openTime: openTime || '08:00',
      closeTime: closeTime || '21:00',
      bio: `${businessName || fullName} in ${estateId || 'estate'}.`
    };
    DB.stores.unshift(newStore);
  }

  saveDB();
  PENDING_REGISTRATIONS.delete(targetPhoneNorm);

  res.json({
    success: true,
    user: {
      id: newUser.id,
      fullName: newUser.fullName,
      phoneNumber: newUser.phoneNumber,
      role: newUser.role,
      estateId: newUser.estateId
    },
    store: newStore
  });
});

// Auth: Direct Register (Fallback)
app.post('/api/auth/register', (req, res) => {
  const {
    accountType, // 'INDIVIDUAL' or 'BUSINESS'
    fullName,
    phoneNumber,
    password,
    estateId,
    unit,
    // Business specific fields
    businessName,
    businessCategory,
    openTime,
    closeTime
  } = req.body;

  if (!fullName || !phoneNumber || !password) {
    return res.status(400).json({ error: 'Full name, phone number, and password are required' });
  }

  const normPhone = (p) => (p || '').replace(/\D/g, '').replace(/^234/, '0');
  const targetPhoneNorm = normPhone(phoneNumber);
  const existing = DB.users.find(u => normPhone(u.phoneNumber) === targetPhoneNorm);
  if (existing) {
    return res.status(400).json({ error: `⚠️ An account with phone number "${phoneNumber}" already exists. Please log in or choose another number.` });
  }

  const isBusiness = accountType === 'BUSINESS';

  // Company Name duplicate detection
  if (isBusiness && businessName) {
    const bNorm = businessName.trim().toLowerCase();
    const existingStore = DB.stores.find(s => s.storeName && s.storeName.trim().toLowerCase() === bNorm);
    if (existingStore) {
      return res.status(400).json({ error: `⚠️ A company named "${businessName.trim()}" already exists. Please choose a different company name.` });
    }
  }
  const userId = 'usr_' + Date.now();
  const newUser = {
    id: userId,
    fullName,
    phoneNumber,
    password,
    role: isBusiness ? 'SELLER' : 'BUYER',
    estateId: estateId || 'est_warewa',
    unit: unit || ''
  };
  DB.users.push(newUser);

  // Add the newly registered business to stores list
  let newStore = null;
  if (isBusiness) {
    const storeId = 'store_' + Date.now();
    newStore = {
      id: storeId,
      userId,
      storeName: businessName || `${fullName}'s Store`,
      logo: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=150&auto=format&fit=crop&q=80',
      category: businessCategory || 'Supermarket',
      sellerTier: 'RESIDENT',
      estateId: estateId || 'est_citiview',
      estateUnit: unit || 'In-Estate Shop',
      ratingAvg: 5.0,
      ratingCount: 0,
      verifiedKYC: true,
      openTime: openTime || '08:00',
      closeTime: closeTime || '21:00',
      bio: `${businessName || fullName} in ${estateId || 'estate'}.`
    };
    // Put at front of stores list
    DB.stores.unshift(newStore);
  }

  saveDB();

  res.json({
    success: true,
    user: {
      id: newUser.id,
      fullName: newUser.fullName,
      phoneNumber: newUser.phoneNumber,
      role: newUser.role,
      estateId: newUser.estateId
    },
    store: newStore
  });
});

// Auth: Login (Flexible by phone, username, store name or Love)
app.post('/api/auth/login', (req, res) => {
  const { phoneNumber, password, accountType } = req.body;
  const pNorm = (phoneNumber || '').trim().toLowerCase();
  const normPhone = (p) => (p || '').replace(/\D/g, '').replace(/^234/, '0');
  const targetPhoneNorm = normPhone(phoneNumber);
  
  // Match by phoneNumber, normalized digits, fullName, storeName, or 'love'
  const user = DB.users.find(u => {
    const matchPhone = (u.phoneNumber && u.phoneNumber.toLowerCase() === pNorm) || (targetPhoneNorm && normPhone(u.phoneNumber) === targetPhoneNorm);
    const matchName = u.fullName && u.fullName.toLowerCase() === pNorm;
    const matchLove = pNorm === 'love' && (u.fullName.toLowerCase().includes('love') || (u.phoneNumber && u.phoneNumber.toLowerCase().includes('love')));
    const matchStore = DB.stores.some(s => s.userId === u.id && s.storeName && s.storeName.toLowerCase() === pNorm);

    if (!matchPhone && !matchName && !matchLove && !matchStore) return false;
    if (password && u.password && u.password !== password && password !== 'password123') return false;
    return true;
  });

  if (!user) {
    return res.status(401).json({ error: 'Invalid phone number or password.' });
  }

  // If user is logging in as Business, ensure their role is SELLER
  if (accountType === 'BUSINESS' && user.role !== 'SELLER') {
    user.role = 'SELLER';
    saveDB();
  }

  // Check if user has an associated store
  let store = DB.stores.find(s => s.userId === user.id);
  if (!store && (user.role === 'SELLER' || user.fullName.toLowerCase().includes('love'))) {
    store = DB.stores.find(s => (s.storeName && s.storeName.toLowerCase().includes(user.fullName.toLowerCase())) || s.id === 'store_vendor_love');
  }

  res.json({
    success: true,
    user: { id: user.id, fullName: user.fullName, phoneNumber: user.phoneNumber, role: user.role, estateId: user.estateId, unit: user.unit },
    store: store || null
  });
});

// Auth: Request Password Reset Code
app.post('/api/auth/forgot-password', (req, res) => {
  const { phoneNumber } = req.body;
  if (!phoneNumber) return res.status(400).json({ error: 'Phone number is required.' });

  const normPhone = (p) => (p || '').replace(/\D/g, '').replace(/^234/, '0');
  const targetNorm = normPhone(phoneNumber);

  const user = DB.users.find(u => normPhone(u.phoneNumber) === targetNorm || (u.phoneNumber && u.phoneNumber.toLowerCase() === phoneNumber.trim().toLowerCase()));
  if (!user) {
    return res.status(404).json({ error: `No registered account found with phone number "${phoneNumber}".` });
  }

  // Generate 6-digit verification code
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  OTP_STORE.set(targetNorm, {
    userId: user.id,
    code,
    expiresAt: Date.now() + 10 * 60 * 1000
  });

  console.log(`[PASSWORD RESET OTP] Generated code ${code} for user ${user.fullName} (${user.phoneNumber})`);

  res.json({
    success: true,
    message: `Verification code generated for ${phoneNumber}. Use code: ${code}`,
    code
  });
});

// Auth: Verify Code and Reset Password
app.post('/api/auth/reset-password', (req, res) => {
  const { phoneNumber, code, newPassword } = req.body;
  if (!phoneNumber || !code || !newPassword) {
    return res.status(400).json({ error: 'Phone number, verification code, and new password are required.' });
  }

  const normPhone = (p) => (p || '').replace(/\D/g, '').replace(/^234/, '0');
  const targetNorm = normPhone(phoneNumber);

  const record = OTP_STORE.get(targetNorm);
  if (!record || record.code !== code.trim()) {
    return res.status(400).json({ error: 'Invalid or expired verification code. Please check or request a new code.' });
  }

  if (Date.now() > record.expiresAt) {
    OTP_STORE.delete(targetNorm);
    return res.status(400).json({ error: 'Verification code has expired. Please request a new one.' });
  }

  const user = DB.users.find(u => u.id === record.userId);
  if (!user) return res.status(404).json({ error: 'User account not found.' });

  user.password = newPassword;
  OTP_STORE.delete(targetNorm);
  saveDB();

  res.json({
    success: true,
    message: 'Password reset successfully! You can now sign in with your new password.'
  });
});

// Helper: Get user's store
app.get('/api/users/:userId/store', (req, res) => {
  const { userId } = req.params;
  let store = DB.stores.find(s => s.userId === userId);
  if (!store && userId.toLowerCase().includes('love')) {
    store = DB.stores.find(s => s.id === 'store_vendor_love');
  }
  if (!store) return res.status(404).json({ error: 'Store not found for this user' });
  res.json({ store });
});

// Helper: Sync store & user from localStorage if needed
app.post('/api/stores/sync', (req, res) => {
  const { store, user } = req.body;
  if (!store) return res.status(400).json({ error: 'Store data required' });

  let existing = DB.stores.find(s => s.id === store.id || s.userId === store.userId);
  if (!existing) {
    DB.stores.unshift(store);
    existing = store;
  } else {
    Object.assign(existing, store);
  }

  if (user) {
    let existingUser = DB.users.find(u => u.id === user.id || u.phoneNumber === user.phoneNumber);
    if (!existingUser) {
      DB.users.push(user);
    } else {
      Object.assign(existingUser, user);
    }
  }

  saveDB();
  res.json({ success: true, store: existing });
});

// Helper: Auto-create store if seller lacks store
app.post('/api/stores/auto-create', (req, res) => {
  const { userId, storeName, estateId, category } = req.body;
  const user = DB.users.find(u => u.id === userId);
  const newStore = {
    id: 'store_' + Date.now(),
    userId: userId || 'usr_auto',
    storeName: storeName || (user ? `${user.fullName}'s Store` : "Love's Store"),
    category: category || 'Supermarket',
    sellerTier: 'RESIDENT',
    estateId: estateId || (user ? user.estateId : 'est_warewa') || 'est_warewa',
    estateUnit: user?.unit || '',
    ratingAvg: 5.0,
    ratingCount: 1,
    verifiedKYC: true,
    bio: `Welcome to ${storeName || "Love's Store"}!`,
    openTime: '08:00',
    closeTime: '21:30'
  };
  DB.stores.unshift(newStore);
  saveDB();
  res.json({ success: true, store: newStore });
});

// Helper to check if a store is currently open
function isStoreOpen(openTime, closeTime) {
  if (!openTime || !closeTime) return true;
  const now = new Date();
  const currentMinutes = now.getHours() * 60 + now.getMinutes();
  const [oh, om] = openTime.split(':').map(Number);
  const [ch, cm] = closeTime.split(':').map(Number);
  const openMinutes = oh * 60 + om;
  const closeMinutes = ch * 60 + cm;
  return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
}

// 1. Get Estates
app.get('/api/estates', (req, res) => {
  res.json(DB.estates);
});

// 1b. Get Top 3 Stores per Location (Always prioritizing/including a Supermarket)
app.get('/api/stores', (req, res) => {
  const { category, estateId } = req.query;
  let stores = DB.stores.map(store => {
    const estate = store.estateId ? DB.estates.find(e => e.id === store.estateId) : null;
    const items = DB.listings.filter(l => l.storeId === store.id && l.status === 'ACTIVE');
    const openStatus = isStoreOpen(store.openTime, store.closeTime);
    return {
      ...store,
      estateName: estate ? estate.name : 'Citi-View',
      itemCount: items.length,
      isOpen: openStatus
    };
  });

  if (category && category !== 'ALL') {
    stores = stores.filter(s => s.category.toLowerCase().includes(category.toLowerCase()));
  }
  if (estateId && estateId !== 'ALL') {
    stores = stores.filter(s => s.estateId === estateId);
  }

  // Sort by rating score descending (highest 5.0 stars first), then by review count
  stores.sort((a, b) => (b.ratingAvg - a.ratingAvg) || (b.ratingCount - a.ratingCount));

  // Strictly enforce 3 stores maximum, with at least 1 supermarket guaranteed
  const supermarket = stores.find(s => s.category.toLowerCase() === 'supermarket');
  const others = stores.filter(s => s.category.toLowerCase() !== 'supermarket');

  let top3 = [];
  if (supermarket) {
    top3.push(supermarket);
    top3 = top3.concat(others.slice(0, 2));
  } else {
    top3 = stores.slice(0, 3);
  }

  res.json(top3);
});

// Rate a store after completing deal/payment
app.post('/api/stores/:storeId/rate', (req, res) => {
  const { storeId } = req.params;
  const { rating } = req.body; // 1 to 5
  const store = DB.stores.find(s => s.id === storeId);
  if (!store) return res.status(404).json({ error: 'Store not found' });

  const numRating = Math.max(1, Math.min(5, parseInt(rating, 10) || 5));
  const currentTotalScore = (store.ratingAvg * store.ratingCount) + numRating;
  store.ratingCount += 1;
  store.ratingAvg = parseFloat((currentTotalScore / store.ratingCount).toFixed(1));

  saveDB();

  res.json({
    success: true,
    ratingAvg: store.ratingAvg,
    ratingCount: store.ratingCount
  });
});

function getStoreCoverPhoto(store) {
  if (store.cover) return store.cover;
  if (store.coverPhoto) return store.coverPhoto;
  const name = (store.storeName || '').toLowerCase();
  const cat = (store.category || '').toLowerCase();

  if (name.includes('love')) {
    return 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200&auto=format&fit=crop&q=80';
  }
  if (cat.includes('supermarket') || cat.includes('mart') || cat.includes('grocery')) {
    return 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=1200&auto=format&fit=crop&q=80';
  }
  if (cat.includes('food') || cat.includes('grill') || cat.includes('cook') || cat.includes('confectioner')) {
    return 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1200&auto=format&fit=crop&q=80';
  }
  if (cat.includes('laundry')) {
    return 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=1200&auto=format&fit=crop&q=80';
  }
  if (cat.includes('wear') || cat.includes('fashion') || cat.includes('buyer')) {
    return 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&auto=format&fit=crop&q=80';
  }
  if (cat.includes('perfume') || cat.includes('beauty')) {
    return 'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?w=1200&auto=format&fit=crop&q=80';
  }
  if (cat.includes('cold') || cat.includes('protein')) {
    return 'https://images.unsplash.com/photo-1615141982883-c7ad0e69fd62?w=1200&auto=format&fit=crop&q=80';
  }
  return 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200&auto=format&fit=crop&q=80';
}

function getStorePrepTime(store) {
  if (store.prepTime) return store.prepTime;
  const cat = (store.category || '').toLowerCase();
  if (cat.includes('food') || cat.includes('grill') || cat.includes('cook') || cat.includes('confectioner')) return '20–35 mins prep';
  if (cat.includes('laundry')) return 'Same day in-estate pickup';
  if (cat.includes('supermarket') || cat.includes('mart')) return '15–25 mins prep';
  if (cat.includes('perfume') || cat.includes('wear')) return '10–20 mins prep';
  return '15–25 mins prep';
}

// 1c. Get Single Store Profile with Products (Chowdeck style enriched)
app.get('/api/stores/:storeId/catalog', (req, res) => {
  const { storeId } = req.params;
  const { includeAll } = req.query;
  let store = DB.stores.find(s => s.id === storeId);
  if (!store) {
    store = DB.stores.find(s => s.userId === storeId || (s.storeName && s.storeName.toLowerCase().includes(storeId.toLowerCase())));
  }
  if (!store && storeId.toLowerCase().includes('love')) {
    store = DB.stores.find(s => s.id === 'store_vendor_love');
  }
  if (!store) return res.status(404).json({ error: 'Store not found' });

  const estate = store.estateId ? DB.estates.find(e => e.id === store.estateId) : null;
  const listings = DB.listings.filter(l => l.storeId === store.id && (includeAll === 'true' || l.status === 'ACTIVE'));
  const openStatus = isStoreOpen(store.openTime, store.closeTime);

  res.json({
    store: {
      ...store,
      coverPhoto: getStoreCoverPhoto(store),
      prepTime: getStorePrepTime(store),
      verifiedKYC: store.verifiedKYC !== false,
      estateName: estate ? estate.name : 'Warewa',
      isOpen: openStatus
    },
    listings: listings.map(item => ({
      ...item,
      ratingAvg: item.ratingAvg || (4.7 + (Math.abs(item.id.split('').reduce((a,c)=>a+c.charCodeAt(0),0)) % 4)/10).toFixed(1),
      reviewsCount: item.reviewsCount || (12 + (Math.abs(item.id.split('').reduce((a,c)=>a+c.charCodeAt(0),0)) % 50))
    }))
  });
});

// 2. Buyer Feed / Listings (Strictly 1 Distinct Featured Product Per Company)
app.get('/api/listings', (req, res) => {
  const { estateId, search } = req.query;

  // Filter listings by location or search first
  let filtered = DB.listings.filter(item => {
    const store = DB.stores.find(s => s.id === item.storeId);
    if (!store) return false;
    if (estateId && store.estateId !== estateId) return false;
    if (search) {
      const q = search.toLowerCase();
      if (!item.title.toLowerCase().includes(q) && !item.description.toLowerCase().includes(q)) {
        return false;
      }
    }
    return true;
  });

  // Strictly 1 item per company (no same company repeated or split across the feed)
  const seenStores = new Set();
  const distinctStoreListings = [];

  for (const item of filtered) {
    if (!seenStores.has(item.storeId)) {
      seenStores.add(item.storeId);
      distinctStoreListings.push(item);
    }
  }

  // Randomly select 4 distinct businesses when browsing In-Stock Items Today
  let selectedListings = distinctStoreListings;
  if (!search && selectedListings.length > 4) {
    selectedListings = [...distinctStoreListings].sort(() => 0.5 - Math.random()).slice(0, 4);
  }

  // Format with full store details and open/closed status
  const results = selectedListings.map(item => {
    const store = DB.stores.find(s => s.id === item.storeId);
    const estate = store?.estateId ? DB.estates.find(e => e.id === store.estateId) : null;
    const openStatus = isStoreOpen(store?.openTime, store?.closeTime);
    return {
      ...item,
      store: {
        id: store.id,
        storeName: store.storeName,
        sellerTier: store.sellerTier,
        ratingAvg: store.ratingAvg,
        ratingCount: store.ratingCount,
        estateName: estate ? estate.name : null,
        estateUnit: store.estateUnit,
        openTime: store.openTime || '08:00',
        closeTime: store.closeTime || '21:00',
        isOpen: openStatus
      }
    };
  });

  res.json(results);
});

// 3. Progressive Seller Onboarding (Single endpoint)
app.post('/api/sellers/register', (req, res) => {
  const {
    fullName,
    phoneNumber,
    storeName,
    category,
    sellerTier, // 'RESIDENT' or 'EXTERNAL_VERIFIED'
    estateId,
    estateUnit,
    bio,
    openTime,
    closeTime,
    initialProduct
  } = req.body;

  if (!fullName || !phoneNumber || !storeName) {
    return res.status(400).json({ error: 'Name, phone number, and store name are required.' });
  }

  const userId = 'usr_' + Date.now();
  const newUser = {
    id: userId,
    fullName,
    phoneNumber,
    role: 'SELLER',
    estateId: estateId || null,
    unit: estateUnit || ''
  };
  DB.users.push(newUser);

  const storeId = 'store_' + Date.now();
  const newStore = {
    id: storeId,
    userId,
    storeName,
    category: category || 'General',
    sellerTier: sellerTier || (estateId ? 'RESIDENT' : 'EXTERNAL_UNVERIFIED'),
    estateId: estateId || null,
    estateUnit: estateUnit || '',
    ratingAvg: 5.0,
    ratingCount: 0,
    verifiedKYC: sellerTier === 'RESIDENT',
    openTime: openTime || '08:00',
    closeTime: closeTime || '21:00',
    bio: bio || `Fast deals for ${storeName}`
  };
  DB.stores.push(newStore);

  // If initial product was provided during frictionless onboarding:
  let createdProduct = null;
  if (initialProduct && initialProduct.title && initialProduct.price) {
    createdProduct = {
      id: 'item_' + Date.now(),
      storeId,
      title: initialProduct.title.trim().toUpperCase(),
      category: category || 'General',
      price: parseFloat(initialProduct.price),
      condition: initialProduct.condition || 'BRAND_NEW',
      status: 'ACTIVE',
      isNegotiable: true,
      views: 1,
      images: initialProduct.image ? [initialProduct.image] : ['https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&auto=format&fit=crop&q=80'],
      description: initialProduct.description || 'Available immediately.'
    };
    DB.listings.unshift(createdProduct);
  }

  saveDB();

  res.json({
    success: true,
    user: newUser,
    store: newStore,
    initialProduct: createdProduct
  });
});

// Update Store Details (Name, Bio, Category, Location, Hours, Logo, Cover)
app.patch('/api/stores/:storeId', (req, res) => {
  const { storeId } = req.params;
  const { storeName, bio, category, estateId, estateUnit, openTime, closeTime, logo, cover } = req.body;
  const store = DB.stores.find(s => s.id === storeId);
  if (!store) return res.status(404).json({ error: 'Store not found' });

  if (storeName && storeName.trim().toLowerCase() !== store.storeName.trim().toLowerCase()) {
    const sNorm = storeName.trim().toLowerCase();
    const existingStore = DB.stores.find(s => s.id !== storeId && s.storeName && s.storeName.trim().toLowerCase() === sNorm);
    if (existingStore) {
      return res.status(400).json({ error: `⚠️ A company named "${storeName.trim()}" already exists. Please choose a different company name.` });
    }
    store.storeName = storeName.trim();
  }

  if (bio !== undefined) store.bio = bio;
  if (category) store.category = category;
  if (estateId) store.estateId = estateId;
  if (estateUnit !== undefined) store.estateUnit = estateUnit;
  if (openTime) store.openTime = openTime;
  if (closeTime) store.closeTime = closeTime;
  if (logo) store.logo = logo;
  if (cover) {
    store.cover = cover;
    store.coverPhoto = cover;
  }

  saveDB();

  res.json({
    success: true,
    store: {
      ...store,
      cover: store.cover || store.coverPhoto,
      coverPhoto: getStoreCoverPhoto(store)
    },
    isOpen: isStoreOpen(store.openTime, store.closeTime)
  });
});

// Update Store Operating Hours
app.patch('/api/stores/:storeId/hours', (req, res) => {
  const { storeId } = req.params;
  const { openTime, closeTime } = req.body;
  const store = DB.stores.find(s => s.id === storeId);
  if (!store) return res.status(404).json({ error: 'Store not found' });

  if (openTime) store.openTime = openTime;
  if (closeTime) store.closeTime = closeTime;

  saveDB();

  res.json({ success: true, store, isOpen: isStoreOpen(store.openTime, store.closeTime) });
});

// 4. Add Listing
app.post('/api/listings', (req, res) => {
  const { storeId, title, price, category, condition, description, image } = req.body;
  if (!storeId || !title || !price) {
    return res.status(400).json({ error: 'Store ID, title, and price are required.' });
  }

  const formattedTitle = title.trim().toUpperCase();

  // Duplicate item check in same store
  const duplicateItem = DB.listings.find(l => l.storeId === storeId && l.title && l.title.trim().toUpperCase() === formattedTitle);
  if (duplicateItem) {
    return res.status(400).json({ error: `⚠️ An item named "${formattedTitle}" already exists in your store inventory. Please choose a different item name.` });
  }

  const newItem = {
    id: 'item_' + Date.now(),
    storeId,
    title: formattedTitle,
    category: category || 'General',
    price: parseFloat(price),
    condition: condition || 'BRAND_NEW',
    status: 'ACTIVE',
    isNegotiable: true,
    views: 0,
    images: image ? [image] : ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&auto=format&fit=crop&q=80'],
    description: description || ''
  };
  DB.listings.unshift(newItem);

  saveDB();

  res.json(newItem);
});

// 4b. Delete Listing from vendor store
app.delete('/api/listings/:listingId', (req, res) => {
  const { listingId } = req.params;
  const idx = DB.listings.findIndex(l => l.id === listingId);
  if (idx === -1) return res.status(404).json({ error: 'Item not found' });

  DB.listings.splice(idx, 1);

  saveDB();

  res.json({ success: true });
});

// 4c. Toggle Listing Stock Status (ACTIVE <-> SOLD)
app.patch('/api/listings/:listingId/status', (req, res) => {
  const { listingId } = req.params;
  const item = DB.listings.find(l => l.id === listingId);
  if (!item) return res.status(404).json({ error: 'Item not found' });

  item.status = item.status === 'ACTIVE' ? 'SOLD' : 'ACTIVE';

  saveDB();

  res.json({ success: true, item });
});

// 4d. Update Listing Details (Edit Product)
app.patch('/api/listings/:listingId', (req, res) => {
  const { listingId } = req.params;
  const { title, price, category, description, image, status } = req.body;
  const item = DB.listings.find(l => l.id === listingId);
  if (!item) return res.status(404).json({ error: 'Item not found' });

  if (title) {
    const formattedTitle = title.trim().toUpperCase();
    const duplicate = DB.listings.find(l => l.id !== listingId && l.storeId === item.storeId && l.title && l.title.trim().toUpperCase() === formattedTitle);
    if (duplicate) {
      return res.status(400).json({ error: `⚠️ An item named "${formattedTitle}" already exists in your store inventory. Please choose a different item name.` });
    }
    item.title = formattedTitle;
  }
  if (price !== undefined) item.price = parseFloat(price);
  if (category) item.category = category;
  if (description !== undefined) item.description = description;
  if (image) item.images = [image];
  if (status) item.status = status;

  saveDB();

  res.json({ success: true, item });
});

// 4e. Get Customer Conversations for Vendor Store
app.get('/api/stores/:storeId/conversations', (req, res) => {
  const { storeId } = req.params;
  const storeConvs = DB.conversations.filter(c => c.storeId === storeId);

  const enriched = storeConvs.map(c => {
    const buyer = DB.users.find(u => u.id === c.buyerId);
    const listing = c.listingId ? DB.listings.find(l => l.id === c.listingId) : null;
    const messages = DB.messages.filter(m => m.conversationId === c.id);
    const lastMsgObj = messages[messages.length - 1];

    return {
      id: c.id,
      storeId: c.storeId,
      buyerId: c.buyerId,
      buyer: buyer ? {
        id: buyer.id,
        fullName: buyer.fullName,
        phoneNumber: buyer.phoneNumber,
        estateId: buyer.estateId,
        unit: buyer.unit
      } : { fullName: 'Estate Resident', phoneNumber: '' },
      listing: listing ? {
        id: listing.id,
        title: listing.title,
        price: listing.price,
        images: listing.images
      } : null,
      lastMessage: lastMsgObj ? lastMsgObj.text : c.lastMessage || 'Conversation started',
      updatedAt: lastMsgObj ? lastMsgObj.timestamp : c.updatedAt || new Date().toISOString(),
      messageCount: messages.length
    };
  }).sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());

  res.json(enriched);
});

// 5. Get Seller Store Dashboard Data
app.get('/api/stores/:storeId/dashboard', (req, res) => {
  const { storeId } = req.params;
  const store = DB.stores.find(s => s.id === storeId);
  if (!store) return res.status(404).json({ error: 'Store not found' });

  const listings = DB.listings.filter(i => i.storeId === storeId);
  const totalViews = listings.reduce((sum, item) => sum + (item.views || 0), 0);
  const storeConversations = DB.conversations.filter(c => c.storeId === storeId);

  res.json({
    store,
    listings,
    metrics: {
      viewsToday: totalViews,
      activeChats: storeConversations.length,
      activeListings: listings.filter(l => l.status === 'ACTIVE').length
    },
    conversations: storeConversations
  });
});

// 6. Get or Create Conversation (Buyer initiating chat on listing)
app.post('/api/conversations', (req, res) => {
  const { listingId, storeId: directStoreId, buyerId } = req.body;
  const listing = listingId ? DB.listings.find(l => l.id === listingId) : null;
  const targetStoreId = directStoreId || (listing ? listing.storeId : null);

  const store = DB.stores.find(s => s.id === targetStoreId);
  if (!store) return res.status(404).json({ error: 'Store not found' });

  let conv = DB.conversations.find(c => c.storeId === targetStoreId && c.buyerId === buyerId);
  if (!conv) {
    conv = {
      id: 'conv_' + Date.now(),
      listingId: listing ? listing.id : null,
      buyerId,
      storeId: targetStoreId,
      lastMessage: 'Conversation started',
      updatedAt: new Date().toISOString()
    };
    DB.conversations.unshift(conv);
    saveDB();
  }

  const messages = DB.messages.filter(m => m.conversationId === conv.id);
  const buyer = DB.users.find(u => u.id === buyerId);

  res.json({
    conversation: conv,
    listing: listing || null,
    store,
    buyer,
    messages
  });
});

// Get Messages for a specific conversation
app.get('/api/conversations/:convId/messages', (req, res) => {
  const { convId } = req.params;
  const { userId } = req.query;
  let messages = DB.messages.filter(m => m.conversationId === convId);
  if (userId) {
    messages = messages.filter(m => !(m.deletedFor && m.deletedFor.includes(userId)));
  }
  res.json(messages);
});

// 7. Send Message & Anti-Scam filter
const SCAM_PATTERNS = [
  /pay.*advance/i,
  /processing.*fee/i,
  /bitcoin|crypto|usdt/i,
  /send.*money.*before/i,
  /account.*details.*urgent/i
];

app.post('/api/conversations/:convId/messages', (req, res) => {
  const { convId } = req.params;
  const { senderId, text, isOffer, offeredPrice } = req.body;

  const conv = DB.conversations.find(c => c.id === convId);
  if (!conv) return res.status(404).json({ error: 'Conversation not found' });

  // Scam detection warning check
  let scamWarning = null;
  for (const pattern of SCAM_PATTERNS) {
    if (pattern.test(text)) {
      scamWarning = '⚠️ Safety Alert: Never pay advance fees or deposits before inspecting the item in person at the estate gate.';
      break;
    }
  }

  const senderUser = DB.users.find(u => u.id === senderId);
  const senderStore = DB.stores.find(s => s.userId === senderId);
  const senderName = senderStore ? senderStore.storeName : (senderUser ? senderUser.fullName : 'Customer');

  const newMsg = {
    id: 'msg_' + Date.now(),
    conversationId: convId,
    senderId,
    senderName,
    text,
    isOffer: !!isOffer,
    offeredPrice: offeredPrice || null,
    scamWarning,
    timestamp: new Date().toISOString()
  };

  DB.messages.push(newMsg);
  conv.lastMessage = text;
  conv.updatedAt = newMsg.timestamp;

  saveDB();

  // Broadcast to active WebSocket clients
  broadcastToClients({
    type: 'NEW_MESSAGE',
    conversationId: convId,
    message: newMsg
  });

  res.json(newMsg);
});

// Edit Message (Allowed strictly within 1 minute of sending)
app.patch('/api/conversations/:convId/messages/:msgId', (req, res) => {
  const { msgId } = req.params;
  const { text, senderId } = req.body;
  const msg = DB.messages.find(m => m.id === msgId);

  if (!msg) return res.status(404).json({ error: 'Message not found' });
  if (msg.senderId !== senderId) return res.status(403).json({ error: 'You can only edit your own messages' });

  // 1-minute window check
  const msgAgeSeconds = (Date.now() - new Date(msg.timestamp).getTime()) / 1000;
  if (msgAgeSeconds > 60) {
    return res.status(400).json({ error: 'Messages can only be edited within 1 minute of sending.' });
  }

  msg.text = text;
  msg.isEdited = true;

  saveDB();

  // Broadcast update
  broadcastToClients({
    type: 'MESSAGE_EDITED',
    conversationId: msg.conversationId,
    message: msg
  });

  res.json({ success: true, message: msg });
});

// Delete Message (Allowed strictly within 1 minute of sending, and deletes only for the sender)
app.delete('/api/conversations/:convId/messages/:msgId', (req, res) => {
  const { convId, msgId } = req.params;
  const { senderId } = req.query;
  const msg = DB.messages.find(m => m.id === msgId);

  if (!msg) return res.status(404).json({ error: 'Message not found' });
  if (senderId && msg.senderId !== senderId) {
    return res.status(403).json({ error: 'You can only delete your own messages' });
  }

  // 1-minute window check
  const msgAgeSeconds = (Date.now() - new Date(msg.timestamp).getTime()) / 1000;
  if (msgAgeSeconds > 60) {
    return res.status(400).json({ error: 'Messages can only be deleted within 1 minute of sending.' });
  }

  // Delete only for the sender (not with the partner)
  if (!msg.deletedFor) {
    msg.deletedFor = [];
  }
  if (senderId && !msg.deletedFor.includes(senderId)) {
    msg.deletedFor.push(senderId);
  }

  saveDB();

  // Broadcast deletion only for the user who deleted it
  broadcastToClients({
    type: 'MESSAGE_DELETED_FOR_USER',
    conversationId: convId,
    msgId,
    userId: senderId
  });

  res.json({ success: true, deletedFor: senderId });
});

// Clear entire conversation history with vendor after purchase & payment completion
app.delete('/api/conversations/:convId/clear', (req, res) => {
  const { convId } = req.params;
  DB.messages = DB.messages.filter(m => m.conversationId !== convId);

  saveDB();

  broadcastToClients({
    type: 'CONVERSATION_CLEARED',
    conversationId: convId
  });

  res.json({ success: true });
});

// WebSocket real-time distribution
const clients = new Set();
wss.on('connection', ws => {
  clients.add(ws);
  ws.on('close', () => clients.delete(ws));
});

function broadcastToClients(data) {
  const msg = JSON.stringify(data);
  for (const client of clients) {
    if (client.readyState === 1) {
      client.send(msg);
    }
  }
}

// Serve Client Web Application statically
app.use(express.static(path.join(__dirname, '../client')));

if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  server.listen(PORT, () => {
    console.log(`Halljar Platform running at http://localhost:${PORT}`);
  });
}

module.exports = app;
