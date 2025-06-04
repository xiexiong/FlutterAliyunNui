package com.example.flutter_aliyun_nui;

import android.text.TextUtils;
import android.util.Log;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class Utils {
    private static final String TAG = "DemoUtils";

    public static int createDir (String dirPath) {
        File dir = new File(dirPath);
        //文件夹是否已经存在
        if (dir.exists()) {
            Log.w(TAG,"The directory [ " + dirPath + " ] has already exists");
            return 1;
        }

        if (!dirPath.endsWith(File.separator)) {//不是以 路径分隔符 "/" 结束，则添加路径分隔符 "/"
            dirPath = dirPath + File.separator;
        }

        //创建文件夹
        if (dir.mkdirs()) {
            Log.d(TAG,"create directory [ "+ dirPath + " ] success");
            return 0;
        }

        Log.e(TAG,"create directory [ "+ dirPath + " ] failed");
        return -1;
    }

//    public static String ip = "";
//    public static String getDirectIp() {
//        Log.i(TAG, "direct ip is " + Utils.ip);
//        Thread th = new Thread(){
//            @Override
//            public void run() {
//                try {
//                    InetAddress addr = InetAddress.getByName("nls-gateway-inner.aliyuncs.com");
//                    Utils.ip = addr.getHostAddress();
//                    Log.i(TAG, "direct ip is " + Utils.ip);
//                } catch (UnknownHostException e) {
//                    e.printStackTrace();
//                }
//            }
//
//        };
//        th.start();
//        try {
//            th.join(5000);
//        } catch (InterruptedException e) {
//            e.printStackTrace();
//        }
//        return ip;
//    }

    public static String getMsgWithErrorCode(int code, String status) {
        String str = "错误码:" + code;
        switch (code) {
            case 140001:
                str += " 错误信息: 引擎未创建, 请检查是否成功初始化, 详情可查看运行日志.";
                break;
            case 140008:
                str += " 错误信息: 鉴权失败, 请关注日志中详细失败原因.";
                break;
            case 140011:
                str += " 错误信息: 当前方法调用不符合当前状态, 比如在未初始化情况下调用pause接口.";
                break;
            case 140013:
                str += " 错误信息: 当前方法调用不符合当前状态, 比如在未初始化情况下调用pause/release等接口.";
                break;
            case 140900:
                str += " 错误信息: tts引擎初始化失败, 请检查资源路径和资源文件是否正确.";
                break;
            case 140901:
                str += " 错误信息: tts引擎初始化失败, 请检查使用的SDK是否支持离线语音合成功能.";
                break;
            case 140903:
                str += " 错误信息: tts引擎任务创建失败, 请检查资源路径和资源文件是否正确.";
                break;
            case 140908:
                str += " 错误信息: 发音人资源无法获得正确采样率, 请检查发音人资源是否正确.";
                break;
            case 140910:
                str += " 错误信息: 发音人资源路径无效, 请检查发音人资源文件路径是否正确.";
                break;
            case 144002:
                str += " 错误信息: 若发生于语音合成, 可能为传入文本超过16KB. 可升级到最新版本, 具体查看日志确认.";
                break;
            case 144003:
                str += " 错误信息: token过期或无效, 请检查token是否有效.";
                break;
            case 144004:
                str += " 错误信息: 语音合成超时, 具体查看日志确认.";
                break;
            case 144006:
                str += " 错误信息: 云端返回未分类错误, 请看详细的错误信息.";
                break;
            case 144103:
                str += " 错误信息: 设置参数无效, 请参考接口文档检查参数是否正确, 也可通过task_id咨询客服.";
                break;
            case 144505:
                str += " 错误信息: 流式语音合成未成功连接服务, 请检查设置参数及服务地址.";
                break;
            case 170008:
                str += " 错误信息: 鉴权成功, 但是存储鉴权信息的文件路径不存在或无权限.";
                break;
            case 170806:
                str += " 错误信息: 请设置SecurityToken.";
                break;
            case 170807:
                str += " 错误信息: SecurityToken过期或无效, 请检查SecurityToken是否有效.";
                break;
            case 240002:
                str += " 错误信息: 设置的参数不正确, 比如设置json参数格式不对, 设置的文件无效等.";
                break;
            case 240005:
                if (status == "init") {
                    str += " 错误信息: 请检查appkey、akId、akSecret、url等初始化参数是否无效或空.";
                } else {
                    str += " 错误信息: 传入参数无效, 请检查参数正确性.";
                }
                break;
            case 240008:
                str += " 错误信息: SDK内部核心引擎未成功初始化.";
                break;
            case 240011:
                str += " 错误信息: SDK未成功初始化.";
                break;
            case 240040:
                str += " 错误信息: 本地引擎初始化失败，可能是资源文件(如kws.bin)损坏.";
                break;
            case 240052:
                str += " 错误信息: 2s未传入音频数据，请检查录音相关代码、权限或录音模块是否被其他应用占用.";
                break;
            case 240063:
                str += " 错误信息: SSL错误，可能为SSL建连失败。比如token无效或者过期，或SSL证书校验失败(可升级到最新版)等等，具体查日志确认.";
                break;
            case 240068:
                str += " 错误信息: 403 Forbidden, token无效或者过期.";
                break;
            case 240070:
                str += " 错误信息: 鉴权失败, 请查看日志确定具体问题, 特别是关注日志 E/iDST::ErrMgr: errcode=.";
                break;
            case 240072:
                str += " 错误信息: 录音文件识别传入的录音文件不存在.";
                break;
            case 240073:
                str += " 错误信息: 录音文件识别传入的参数错误, 比如audio_address不存在或file_path不存在或其他参数错误.";
                break;
            case 10000016:
                if (status.contains("403 Forbidden")) {
                    str += " 错误信息: 流式语音合成未成功连接服务, 请检查设置的账号临时凭证.";
                } else if (status.contains("404 Forbidden")) {
                    str += " 错误信息: 流式语音合成未成功连接服务, 请检查设置的服务地址URL.";
                } else {
                    str += " 错误信息: 流式语音合成未成功连接服务, 请检查设置的参数及服务地址.";
                }
                break;
            case 40000004:
                str += " 错误信息: 长时间未收到指令或音频.";
                break;
            case 40000010:
                str += " 错误信息: 此账号试用期已过, 请开通商用版或检查账号权限.";
                break;
            case 41010105:
                str += " 错误信息: 长时间未收到人声，触发静音超时.";
                break;
            case 999999:
                str += " 错误信息: 库加载失败, 可能是库不支持当前activity, 或库加载时崩溃, 可详细查看日志判断.";
                break;
            default:
                str += " 未知错误信息, 请查看官网错误码和运行日志确认问题.";
        }
        return str;
    }

    public static boolean isExist(String filename) {
        File file = new File(filename);
        if (!file.exists()) {
            Log.e(TAG, "打不开：" + filename);
            return false;
        } else {
            return true;
        }
    }

    public static boolean isFileExists(String filePath) {
        File file = new File(filePath);
        return file.exists() && file.isFile();
    }

    private static String capitalize(String str) {
        if (TextUtils.isEmpty(str)) {
            return str;
        }
        char[] arr = str.toCharArray();
        boolean capitalizeNext = true;

        StringBuilder phrase = new StringBuilder();
        for (char c : arr) {
            if (capitalizeNext && Character.isLetter(c)) {
                phrase.append(Character.toUpperCase(c));
                capitalizeNext = false;
                continue;
            } else if (Character.isWhitespace(c)) {
                capitalizeNext = true;
            }
            phrase.append(c);
        }

        return phrase.toString();
    }

    public static String extractVersion(String input) {
        if (input.isEmpty()) {
            return "";
        }
        Pattern pattern = Pattern.compile("-(\\w+)-");
        Matcher matcher = pattern.matcher(input);

        if (matcher.find()) {
            return matcher.group(1);
        } else {
            return "";
        }
    }

    // 此处只为DEMO中离线语音合成演示，实际产品中不保证下载链接不会变化，请客户自行管理离线语音包
    private static final Map<String, String> boutiquevoice_files_map = new HashMap<String, String>() {{
        put("aijia", "https://gw.alipayobjects.com/os/bmw-prod/a9f6fd18-cf0c-45a0-83b0-718ccfa36212.zip");
        put("aicheng", "https://gw.alipayobjects.com/os/bmw-prod/15b64d3f-ee9b-409a-bac6-e319596dfe91.zip");
        put("aiqi", "https://gw.alipayobjects.com/os/bmw-prod/b7b1152b-0174-44e9-88a8-2525695eb45c.zip");
        put("aida", "https://gw.alipayobjects.com/os/bmw-prod/5b44533f-0d00-43f6-8bbc-f8752afec4df.zip");
        put("aihao", "https://gw.alipayobjects.com/os/bmw-prod/d95c5709-8a2f-4473-959d-08a8a1f0019c.zip");
        put("aishuo", "https://gw.alipayobjects.com/os/bmw-prod/1b4b3829-b95c-411c-b960-21f0cef77fc9.zip");
        put("aiying", "https://gw.alipayobjects.com/os/bmw-prod/ce7b0092-51e3-41f6-9119-0f0511355f80.zip");
        put("aitong", "https://gw.alipayobjects.com/os/bmw-prod/5637b419-1515-46f5-b9bf-52b381e0a3a8.zip");
        put("abby", "https://gw.alipayobjects.com/os/bmw-prod/de45872e-f2a4-4c75-8c9c-6cb1570cf39e.zip");
        put("andy", "https://gw.alipayobjects.com/os/bmw-prod/3798c839-c5e6-4ff1-b69e-004bbf51be64.zip");
        put("annie", "https://gw.alipayobjects.com/os/bmw-prod/96affc9e-9a20-4dee-8ae7-a0aa8953493c.zip");
    }};
    private static final Map<String, String> standard_voice_files_map = new HashMap<String, String>() {{
        put("aijia", "https://gw.alipayobjects.com/os/bmw-prod/a9f6fd18-cf0c-45a0-83b0-718ccfa36212.zip");
        put("aicheng", "https://gw.alipayobjects.com/os/bmw-prod/15b64d3f-ee9b-409a-bac6-e319596dfe91.zip");
        put("xiaoyun", "https://gw.alipayobjects.com/os/bmw-prod/43a0c626-c40d-4762-92b0-2c0e1fa8ef79.zip");
        put("xiaoda", "https://gw.alipayobjects.com/os/bmw-prod/60d0b806-6518-4cb1-91b4-6807fd8d3d49.zip");
        put("xiaogang", "https://gw.alipayobjects.com/os/bmw-prod/329c607b-3235-4fd0-8bc2-c87ada55bb36.zip");
        put("xiaoqi", "https://gw.alipayobjects.com/os/bmw-prod/591aab02-82e2-4774-b76b-91c80e41813d.zip");
        put("xiaoxia", "https://gw.alipayobjects.com/os/bmw-prod/a346db66-357a-4708-8ad6-c7f1e6a9691d.zip");
    }};
    public static Map<String, String> getVoiceFilesMap(String sdk_code) {
        if (sdk_code.equals("software_nls_tts_offline_standard")) {
            return standard_voice_files_map;
        } else if (sdk_code.equals("software_nls_tts_offline")) {
            return boutiquevoice_files_map;
        } else {
            return standard_voice_files_map;
        }
    }
    public static boolean downloadZipFile(String font_name, String link, String path) {
        String targetDir = path;
        String targetFile = targetDir + "/" + font_name;
        String targetZip = targetFile + ".zip";
        File targetPath = new File(targetFile);
        if (targetPath.exists()) {
            Log.i(TAG, font_name + " is existent.");
            return true;
        } else {
            // downloading ...
            try {
                URL url = new URL(link);
                Log.i(TAG, "url link: " + link);
                HttpURLConnection urlConnection = (HttpURLConnection) url.openConnection();
                urlConnection.connect();

                // 检查服务器的响应
                if (urlConnection.getResponseCode() != HttpURLConnection.HTTP_OK) {
                    Log.e(TAG, "Http URL connect failed " + urlConnection.getResponseCode());
                    return false;
                }

                InputStream inputStream = urlConnection.getInputStream();
                FileOutputStream fileOutputStream = new FileOutputStream(targetZip);

                byte[] buffer = new byte[4096];
                int bytesRead;
                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    fileOutputStream.write(buffer, 0, bytesRead);
                }

                // 关闭流
                fileOutputStream.flush();
                fileOutputStream.close();
                inputStream.close();

                try {
                    unzip(targetZip, targetDir);
                } catch (IOException e) {
                    e.printStackTrace();
                }

                String md5 = getFileMD5(targetPath);
                Log.i(TAG, "File:" + targetPath + "  md5:" + md5);

                return true;
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        return false;
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder hexString = new StringBuilder();
        for (byte b : bytes) {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) {
                hexString.append('0');
            }
            hexString.append(hex);
        }
        return hexString.toString();
    }
    public static String getFileMD5(File file) {
        try (FileInputStream fis = new FileInputStream(file)) {
            MessageDigest md5 = MessageDigest.getInstance("MD5");
            byte[] buffer = new byte[8192];
            int read;

            while ((read = fis.read(buffer)) != -1) {
                md5.update(buffer, 0, read);
            }

            byte[] digest = md5.digest();
            return bytesToHex(digest);
        } catch (IOException | NoSuchAlgorithmException e) {
            e.printStackTrace();
            return null;
        }
    }

    private static File newFile(File destinationDir, ZipEntry zipEntry) throws IOException {
        File destFile = new File(destinationDir, zipEntry.getName());
        return destFile;
    }
    private static void unzip(String zipFilePath, String destDirectory) throws IOException {
        File dir = new File(destDirectory);
        // 创建解压目标文件夹
        if (!dir.exists()) {
            dir.mkdir();
        }

        byte[] buffer = new byte[1024];
        ZipInputStream zis = new ZipInputStream(new FileInputStream(zipFilePath));
        ZipEntry zipEntry = zis.getNextEntry();

        while (zipEntry != null) {
            File newFile = newFile(dir, zipEntry);
            if (zipEntry.isDirectory()) {
                newFile.mkdir();
            } else {
                // 确保文件的父目录存在
                new File(newFile.getParent()).mkdirs();
                FileOutputStream fos = new FileOutputStream(newFile);
                int len;
                while ((len = zis.read(buffer)) > 0) {
                    fos.write(buffer, 0, len);
                }
                fos.close();
            }
            zipEntry = zis.getNextEntry();
        }
        zis.closeEntry();
        zis.close();
    }

    private static String getFileNameFromUrl(HttpURLConnection connection) {
        String fileName = null;

        // 从 Content-Disposition header 获取文件名
        String disposition = connection.getHeaderField("Content-Disposition");
        if (disposition != null) {
            String[] parts = disposition.split(";");
            for (String part : parts) {
                if (part.trim().startsWith("filename")) {
                    fileName = part.substring(part.indexOf('=') + 2, part.length() - 1);
                    break;
                }
            }
        }

        // 如果没有找到文件名，可以从 URL 中提取文件名
        if (fileName == null) {
            String urlPath = connection.getURL().getPath();
            fileName = urlPath.substring(urlPath.lastIndexOf('/') + 1);
        }

        // 使用默认文件名，如果实在无法获取
        if (fileName == null || fileName.isEmpty()) {
            fileName = "downloaded_file"; // 默认文件名
        }

        return fileName;
    }

    public static String downloadFile(String link, String dir) {
        String targetDir = dir;

        // downloading ...
        try {
            URL url = new URL(link);
            Log.i(TAG, "url link: " + link);
            HttpURLConnection urlConnection = (HttpURLConnection) url.openConnection();
            urlConnection.connect();

            // 检查服务器的响应
            if (urlConnection.getResponseCode() != HttpURLConnection.HTTP_OK) {
                Log.e(TAG, "Http URL connect failed " + urlConnection.getResponseCode());
                return "";
            }

            InputStream inputStream = urlConnection.getInputStream();
            String fileName = getFileNameFromUrl(urlConnection);
            if (fileName == null) {
                Log.e(TAG, "Cannot get file name from url");
                return "";
            } else {
                Log.i(TAG, "Get file name from url " + fileName);
            }

            File targetPath = new File(targetDir, fileName);
            String targetFilePath = targetPath.getPath();
            if (targetPath.exists()) {
                Log.i(TAG, targetFilePath + " is existent.");
            } else {
                FileOutputStream fileOutputStream = new FileOutputStream(targetPath);

                byte[] buffer = new byte[4096];
                int bytesRead;
                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    fileOutputStream.write(buffer, 0, bytesRead);
                }

                // 关闭流
                fileOutputStream.flush();
                fileOutputStream.close();

            }
            inputStream.close();
            String md5 = getFileMD5(targetPath);
            Log.i(TAG, "File:" + targetFilePath + "  md5:" + md5);
            return targetFilePath;
        } catch (Exception e) {
            e.printStackTrace();
        }

        return "";
    }

    public static String getFileExtension(String filePath) {
        if (isFileExists(filePath)) {
            File file = new File(filePath);
            String fileName = file.getName();
            if (fileName.lastIndexOf('.') > 0) {
                return fileName.substring(fileName.lastIndexOf('.') + 1);
            } else {
                return ""; // 如果没有扩展名，返回空字符串
            }
        } else {
            return "";
        }
    }

    public static String getAddressExtension(String address) {
        if (address.lastIndexOf('.') > 0) {
            return address.substring(address.lastIndexOf('.') + 1);
        } else {
            return "";
        }
    }

    public static boolean fixWavHeader(String wavPath) {
        if (isFileExists(wavPath)) {
            try {
                File wavFile = new File(wavPath);
                FileInputStream fis = new FileInputStream(wavFile);
                byte[] header = new byte[44]; // WAV头长度为44字节
                if (fis.read(header) != 44) {
                    Log.e(TAG, "WAV header is not valid!");
                    fis.close();
                    return false;
                }

                String riff = new String(header, 0, 4);
                String wave = new String(header, 8, 4);

                if (riff.equals("RIFF") && wave.equals("WAVE")) {
                } else {
                    Log.e(TAG, "WAV file is not valid!");
                    fis.close();
                    return false;
                }

                // 获取数据部分
                byte[] data = new byte[(int) (wavFile.length() - 44)];
                fis.read(data);
                fis.close();

                // 计算实际数据长度
                int actualDataLength = data.length;

                // 更新WAV头中的数据长度
                // 数据长度：从第40字节开始的4字节
                int dataSizePosition = 40;
                header[dataSizePosition] = (byte) (actualDataLength & 0xFF);
                header[dataSizePosition + 1] = (byte) ((actualDataLength >> 8) & 0xFF);
                header[dataSizePosition + 2] = (byte) ((actualDataLength >> 16) & 0xFF);
                header[dataSizePosition + 3] = (byte) ((actualDataLength >> 24) & 0xFF);

                // 写入修订后的WAV文件
                FileOutputStream fos = new FileOutputStream(wavFile);
                fos.write(header);
                fos.write(data);
                fos.close();
            } catch (IOException e) {
                e.printStackTrace();
                return false;
            }
        } else {
            return false;
        }
        return true;
    }

    public static String getDeviceIdFromFile(String accessFilePath, String defaultDeviceId) {
        if (isFileExists(accessFilePath)) {
        } else {
            Log.w(TAG, "new device id, use default " + defaultDeviceId);
            return defaultDeviceId;
        }

        try {
            String deviceId;
            File file = new File(accessFilePath);
            BufferedReader bufferedReader = new BufferedReader(new FileReader(file));
            StringBuilder stringBuilder = new StringBuilder();
            String line;
            while ((line = bufferedReader.readLine()) != null) {
                stringBuilder.append(line);
            }
            bufferedReader.close();

            // 读取JSON内容并获取String和int对象
            String jsonContent = stringBuilder.toString();
            JSONObject jsonObject = JSON.parseObject(jsonContent);
            if (jsonObject.getString("device_id") != null &&
                    !jsonObject.getString("device_id").isEmpty()) {
                deviceId = jsonObject.getString("device_id");
                Log.i(TAG, "Get device id: " + deviceId);
                return deviceId;
            } else {
                Log.w(TAG, "cannot find device id, use default " + defaultDeviceId);
                return defaultDeviceId;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return defaultDeviceId;
    }

    public static boolean saveDeviceIdToFile(String accessFilePath, String deviceId) {
        if (isFileExists(accessFilePath)) {
        } else {
            return false;
        }

        try {
            File file = new File(accessFilePath);
            BufferedReader bufferedReader = new BufferedReader(new FileReader(file));
            StringBuilder stringBuilder = new StringBuilder();
            String line;
            while ((line = bufferedReader.readLine()) != null) {
                stringBuilder.append(line);
            }
            bufferedReader.close();

            // 读取JSON内容并获取String和int对象
            String jsonContent = stringBuilder.toString();
            JSONObject jsonObject = JSON.parseObject(jsonContent);
            jsonObject.put("device_id", deviceId);

            FileWriter fileWriter = new FileWriter(accessFilePath);
            BufferedWriter bufferedWriter = new BufferedWriter(fileWriter);
            bufferedWriter.write(jsonObject.toString());
            Log.i(TAG, "Save " + jsonObject.toString() + "into " + accessFilePath);
            bufferedWriter.close();
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
        return true;
    }
}
