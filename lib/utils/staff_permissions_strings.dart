/// تسميات صلاحيات الموظفين بالعربية والإنجليزية (المتطلب 74).
Map<String, String> staffPermissionLabels(bool isArabic) => {
      'can_manage_bookings': isArabic ? 'إدارة الحجوزات' : 'Manage bookings',
      'can_manage_services':
          isArabic ? 'إدارة طلبات الخدمات' : 'Manage service requests',
      'can_check_in_out':
          isArabic ? 'تسجيل الدخول والخروج' : 'Check-in and checkout',
      'can_view_finance':
          isArabic ? 'عرض البيانات المالية' : 'View financial data',
    };
